SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='spDicoRegenerarRegistroContable')
DROP PROCEDURE spDicoRegenerarRegistroContable
GO
CREATE PROCEDURE [dbo].[spDicoRegenerarRegistroContable]
				 @Empresa char(5),
                 @ContID INT,
                 @Silencio BIT=0,
				 @Debug BIT = 0

AS    
BEGIN    
  DECLARE   @Modulo char(5)
          , @ID INT
          , @Origen varchar(20)
          , @OrigenID varchar(20)
          , @OrigenTipoCont VARCHAR(5)
          , @OrigenCont VARCHAR(20)
          , @OrigenIDCont   VARCHAR(20)
          , @OrigenTipoReg  VARCHAR(5)
          , @OrigenReg  VARCHAR(20)
          , @OrigenIDReg    VARCHAR(20)
          , @MovsDFlujo INT
          , @Sucursal   INT
          , @TotalContRegGAS    FLOAT
          , @TotalContGAS       FLOAT
          , @IDGenerado     INT

               --SELECT @Empresa = '05', /*@Modulo='VTAS',*/ @ContID=14390819

               SELECT @Modulo=ISNULL(c.OrigenTipo,mf.OModulo), @Origen=ISNULL(c.origen,mf.OMov), @OrigenID=ISNULL(c.origenid,mf.OMovID) ,
			   @ID = mf.OID -- GON 17/06/24 - se cambia ya que en tesorería podría traer el ID incorrecto ya que se puede repetir el MovID
               FROM Cont c WITH(NOLOCK)
               JOIN MovFlujo AS mf WITH(NOLOCK) ON mf.DID=c.ID AND mf.Sucursal = c.Sucursal AND mf.Empresa = c.Empresa AND mf.DModulo='CONT'
			   AND  ISNULL(mf.Cancelado,0) = 0
               WHERE c.id=@ContID
               
			   IF @Debug=1
               SELECT @Modulo,@Origen,@OrigenID, @ID
               /*
               IF @Modulo='GAS' 
               SELECT @ID=ID FROM Gasto WHERE Empresa=@Empresa AND Mov=@Origen AND MovID=@OrigenID
               ELSE
               IF @Modulo='DIN' 
               SELECT @ID=ID FROM Dinero WHERE Empresa=@Empresa AND Mov=@Origen AND MovID=@OrigenID
               ELSE 
               IF @Modulo='VTAS' 
               SELECT @ID=ID FROM Venta WHERE Empresa=@Empresa AND Mov=@Origen AND MovID=@OrigenID

               IF @Modulo='COMS' 
               SELECT @ID=ID FROM Compra WHERE Empresa=@Empresa AND Mov=@Origen AND MovID=@OrigenID
--------------AMM 30012023
			   IF @Modulo='CXP'   
               SELECT @ID=ID FROM Cxp WHERE Empresa=@Empresa AND Mov=@Origen AND MovID=@OrigenID  
                */
				-- GON 17/06/24 - se cambia ya que en tesorería podría traer el ID incorrecto ya que se puede repetir el MovID


               IF ISNULL(@ID,0) >0 OR ISNULL(@ContID,0)>0
               BEGIN
               IF EXISTS(SELECT ID FROM ContREG WHERE ID=@ContID)
               DELETE FROM ContReg WHERE ID=@ContID
               
               --SELECT @ID

			   IF @Modulo='GAS'
               BEGIN
					
                INSERT ContReg ( ID, Empresa,  Sucursal,         Modulo,  ModuloID, Cuenta, SubCuenta, Concepto, ContactoEspecifico, Debe, Haber)  
                SELECT c.ID, @Empresa, d.SucursalContable, @Modulo, @ID,      d.Cuenta, d.SubCuenta, d.Concepto, ISNULL(dd.EndosarA,c.Contacto),  
                 -- d.Debe*(dd.Importe/cd.Importe), d.Haber*(dd.Importe/cd.Importe)  
                       d.Debe*(convert(float,dd.Importe)/convert(float,cd.Importe) ),  
                       d.Haber*(convert(float,dd.Importe)/convert(float,cd.Importe) )  
                  FROM Cont c  WITH(NOLOCK) 
                  JOIN Contd d WITH(NOLOCK) ON c.id = d.id   
                  --JOIN MovFlujo m ON m.DID = c.id AND m.DModulo = 'CONT' AND m.OModulo = 'GAS'  
                  --JOIN Gasto cd ON cd.ID = m.OID  
                  JOIN Gasto cd WITH(NOLOCK) ON  cd.ID = @ID --cd.Mov = c.Origen AND cd.MovID = c.OrigenID AND cd.Empresa = c.Empresa  
                  JOIN Gastod dd WITH(NOLOCK) ON dd.ID = cd.ID  
                 WHERE c.Id = @ContID
                    
                                                                                                           
                   IF @@ROWCOUNT  = 0  
                       INSERT ContReg (  
                       ID, Empresa,  Sucursal,         Modulo,  ModuloID, Cuenta, SubCuenta, Concepto, ContactoEspecifico, Debe, Haber)  
                       SELECT d.ID, @Empresa, d.SucursalContable, @Modulo, @ID,      d.Cuenta, d.SubCuenta, d.Concepto, ISNULL(d.ContactoEspecifico,C.Contacto), d.Debe, d.Haber  
                         FROM ContD  d WITH(NOLOCK)
                         JOIN Cont AS c  WITH(NOLOCK) ON c.ID = d.ID 
                       WHERE d.ID = @ContID --AND Renglon = @Renglon AND RenglonSub = @RenglonSub  
                   ELSE
                   BEGIN
                   	    
                   	    --Obtiene el total de la poliza de gasto
                   	    SELECT @TotalContGAS= SUM(ISNULL(cd.Debe,0)-ISNULL(cd.Haber,0))
                        FROM ContD AS cd WITH(NOLOCK)
                        WHERE cd.ID=@ContID  
               
                        --Total de la poliza registrada en ContReg
                        SELECT @TotalContRegGAS =SUM(ISNULL(cr.Debe,0)-ISNULL(cr.Haber,0))
                        FROM ContReg AS cr WITH(NOLOCK)
                        WHERE cr.ID=@ContID
                        
                        --Se valida que en caso de no ser iguales se regenera nuevamente el contReg de esta poliza usando lo que tiene la poliza registrado
                   		IF  @TotalContRegGAS<>@TotalContGAS
                   	    BEGIN
                   	    	DELETE FROM ContReg WHERE ID=@ContID
                   	    	
                   	    	INSERT ContReg (ID, Empresa,  Sucursal,         Modulo,  ModuloID, Cuenta, SubCuenta, Concepto, ContactoEspecifico, Debe, Haber)  
                                   SELECT d.ID, @Empresa, d.SucursalContable, @Modulo, @ID,      d.Cuenta, d.SubCuenta, d.Concepto, ISNULL(d.ContactoEspecifico,c.Contacto), d.Debe, d.Haber  
                                     FROM ContD  d WITH(NOLOCK)
                                     JOIN Cont AS c WITH(NOLOCK) ON c.ID = d.ID
                                   WHERE d.ID = @ContID  	
                   	    END
                   	END
                   	    
                 
                END
                ELSE
                BEGIN
                IF @Modulo= 'DIN'
                BEGIN

                INSERT ContReg ( ID, Empresa,  Sucursal,         Modulo,  ModuloID, Cuenta, SubCuenta, Concepto, ContactoEspecifico, Debe, Haber)  
                SELECT c.ID, @Empresa, d.SucursalContable, @Modulo, @ID,      d.Cuenta, d.SubCuenta, d.Concepto, ISNULL(a.Contacto,c.Contacto),   
                       d.Debe*(convert(float,dd.Importe)/convert(float,cd.Importe) ),  
                       d.Haber*(convert(float,dd.Importe)/convert(float,cd.Importe) )  
                  FROM Cont c   WITH(NOLOCK)
                  JOIN Contd d WITH(NOLOCK) ON c.id = d.id   
--                  JOIN MovFlujo m ON m.DID = c.id AND m.DModulo = 'CONT' AND m.OModulo = 'DIN'  
--                  JOIN Dinero cd ON cd.ID = m.OID  
                  JOIN Dinero cd WITH(NOLOCK) ON cd.ID = @ID-- cd.Mov = c.Origen AND cd.MovID = c.OrigenID AND cd.Empresa = c.Empresa AND CtaDinero = @CtaDinero  
                  JOIN Dinerod dd WITH(NOLOCK) ON dd.ID = cd.ID  
                  JOIN Dinero a WITH(NOLOCK) ON dd.Aplica = a.Mov AND dd.AplicaID = a.MovID AND a.Empresa = @Empresa  
                 WHERE c.Id = @ContID --AND d.Renglon = @Renglon AND d.RenglonSub = @RenglonSub  
  
				IF @Debug=1
				SELECT * FROM ContReg WHERE ID=@ContID

                 IF @@ROWCOUNT  = 0  
                    INSERT ContReg (  
                   ID, Empresa,  Sucursal,         Modulo,  ModuloID, Cuenta, SubCuenta, Concepto, ContactoEspecifico, Debe, Haber)  
                   SELECT d.ID, @Empresa, d.SucursalContable, @Modulo, @ID,      d.Cuenta, d.SubCuenta, d.Concepto, ISNULL(d.ContactoEspecifico,c.Contacto), d.Debe, d.Haber  
                     FROM ContD d WITH(NOLOCK)
                     JOIN Cont AS c WITH(NOLOCK) ON c.ID = d.ID 
                    WHERE d.ID = @ContID --AND Renglon = @Renglon AND RenglonSub = @RenglonSub  
				
				IF @Debug=1
				SELECT * FROM ContReg WHERE ID=@ContID
                    
                    --SELECT * FROM ContReg AS cr WHERE cr.ModuloID=@ID AND ID=@ContID

                END
                ELSE
                BEGIN
                   
				   --SELECT   d.ID, @Empresa, d.SucursalContable, @Modulo, @ID,      d.Cuenta,d.SubCuenta, d.Concepto, d.ContactoEspecifico,c.Contacto, d.Debe, d.Haber  
       --               FROM ContD  d
					  --JOIN Cont c ON c.ID=d.ID 
       --              WHERE d.ID = @ContID  
				   
				   IF NOT EXISTS (SELECT * FROM ContReg WHERE ID = @ContID)  
                    INSERT ContReg (  
                   ID, Empresa,  Sucursal,         Modulo,  ModuloID, Cuenta, SubCuenta, Concepto, ContactoEspecifico, Debe, Haber)  
                    SELECT d.ID, @Empresa, d.SucursalContable, @Modulo, @ID,      d.Cuenta, d.SubCuenta, d.Concepto, ISNULL(d.ContactoEspecifico,c.Contacto), d.Debe, d.Haber  
                      FROM ContD d WITH(NOLOCK)
                      JOIN Cont AS c WITH(NOLOCK) ON c.ID = d.ID 
                     WHERE d.ID = @ContID  
               END
               END

            END
	--IGGR. 10/05/2024. Se agrega actualizacion de los datos de origen de la poliza cuando estos esten vacios y existan en el MovFlujo
	SELECT @OrigenTipoCont=c.OrigenTipo
	      ,@Sucursal=c.Sucursal
	      ,@OrigenIDCont=c.OrigenID
	FROM Cont AS c WITH(NOLOCK)
	WHERE ID=@ContID
	
	--Valida que no se tenga OrigenID del movimiento de contabilidad
	IF @OrigenIDCont IS NULL
	BEGIN
		--Se valida que el movimiento de contabilidad exista en el movflujo
		IF EXISTS(SELECT 1 FROM MovFlujo AS mf WHERE mf.DID=@ContID AND mf.Sucursal=@Sucursal AND mf.Empresa=@Empresa AND mf.DModulo='CONT')
		BEGIN
			--Se contabiliza el numero de registros de destino en el movflujo que sean del ID de la poliza
			 SELECT @MovsDFlujo=COUNT(mf.DID)
			 FROM MovFlujo AS mf WITH(NOLOCK)
			 WHERE mf.DID=@ContID
			 AND mf.Sucursal=@Sucursal
			 AND mf.Empresa=@Empresa
			 AND mf.DModulo='CONT'
			 
			 --Si el numero de registros en el movflujo de la poliza destino es mayor a 1
			 IF @MovsDFlujo > 1
			 BEGIN
			 	   --Se obtinene el modulo y moduloID que correspondan al registrado en ContReg y que exista en movflujo
			 	   SELECT @OrigenTipoReg=cr.Modulo
			 	         ,@OrigenIDReg=cr.ModuloID
			 	   FROM ContReg AS cr WITH(NOLOCK)
			 	   WHERE cr.ID=@ContID
			 	   
			 	   SELECT @OrigenTipoCont=mf.OModulo
			 	         ,@OrigenCont=mf.OMov
			 	         ,@OrigenIDCont=mf.OMovID
			 	   FROM MovFlujo AS mf WITH(NOLOCK)
			 	   WHERE mf.DID=@ContID
			 	   AND mf.Sucursal=@Sucursal
			 	   AND mf.Empresa=@Empresa
			 	   AND mf.DModulo='CONT'
			 	   AND mf.OModulo=@OrigenTipoReg
			 	   AND mf.OMovID=@OrigenIDReg
			 	   
			 	   --Se actualiza la poliza correspondiente con el modulo y su debido consecutivo
			 	   UPDATE Cont SET OrigenTipo = @OrigenTipoCont
			 	                   ,Origen = @OrigenCont
			 	                   ,OrigenID = @OrigenIDCont
			 	   WHERE ID=@ContID
			 	   
			 END
			 --En caso de solo exista un solo destino de poliza en mov flujo
			 ELSE
			 BEGIN
			 	     SELECT @OrigenTipoCont=mf.OModulo
			 	         ,@OrigenCont=mf.OMov
			 	         ,@OrigenIDCont=mf.OMovID
			 	   FROM MovFlujo AS mf WITH(NOLOCK)
			 	   WHERE mf.DID=@ContID
			 	   AND mf.Sucursal=@Sucursal
			 	   AND mf.Empresa=@Empresa
			 	   AND mf.DModulo='CONT'
			 	   
			 	   --Se actualiza la poliza correspondiente con el modulo y su debido consecutivo
			 	   UPDATE Cont SET OrigenTipo = @OrigenTipoCont
			 	                   ,Origen = @OrigenCont
			 	                   ,OrigenID = @OrigenIDCont
			 	   WHERE ID=@ContID
			 END
		END
		ELSE
		BEGIN
			     --Se actualiza la poliza correspondiente con el modulo y su debido consecutivo que seran los mismos de la poliza porque es una poliza a mano
			 	   UPDATE Cont SET OrigenTipo = 'CONT'
			 	                   ,Origen = Mov
			 	                   ,OrigenID = MovID
			 	   WHERE ID=@ContID
			 	   
			 	   --Actualiza el cont reg de la poliza con el mismo movid de la poliza ya que estas polizas son a mano
			 	   UPDATE r SET r.Modulo='CONT'
			 	                ,r.ModuloID=c.MovID
			 	   FROM ContReg AS r WITH(NOLOCK)
			 	   JOIN Cont AS c WITH(NOLOCK) ON c.ID = r.ID
			 	   WHERE r.id=@ContID
		END
		
	END
	
	--Fin IGGR
	
	--Se valida si el bit de silencio esta apagado no se muestran los mensajes de salida
	IF @Silencio=1
	    SELECT 'Proceso realizado con éxito, se regeneró el Registro Contable de la Póliza con el ID:'+ CAST(@ContID AS VARCHAR(10)) + ' de la empresa: ' + @Empresa
	
	END
GO


