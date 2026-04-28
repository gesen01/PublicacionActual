SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='spDWHVerBalanzaContabilidad')
DROP PROCEDURE spDWHVerBalanzaContabilidad
GO
CREATE PROC spDWHVerBalanzaContabilidad 
		  @Cuenta    CHAR(20),  
          @Empresa   CHAR(5),  
          @Sucursal  INT,  
          @Ejercicio INT,  
          @PeriodoD  INT,  
          @PeriodoA  INT,  
          @Moneda    CHAR(10)  
AS  
  BEGIN  
      DECLARE @EsAcumulativa BIT,  
    @Ok    VARCHAR(50),  
                @Servidor  varchar(30),  
    @Base   varchar(30),  
    @BaseT   varchar(100),  
    @Comando  varchar(8000),  
    @Rama   varchar(10),  
    @PeriodoAnt  INT,  
    @Clave   varchar(100)  
    
    
 SET ANSI_NULLS ON  
 SET ANSI_WARNINGS ON  
 SET TRANSACTION isolation level READ uncommitted  
  
    
      SELECT @EsAcumulativa = Esacumulativa  
      FROM   Cta  
      WHERE  Cuenta = @Cuenta  
  
      SELECT @Ok = 'OK',  @PeriodoAnt=@PeriodoD-1  
  
      IF @EsAcumulativa = 1  
        BEGIN  
            CREATE TABLE #cont  
              (  
                 Cuenta        CHAR(20) NULL,  
                 Descripcion   VARCHAR(255) NULL,  
                 Rama          CHAR(20) NULL,  
                 Esacumulativa BIT NULL,  
                 Tipo          CHAR(15) NULL,  
                 Inicio        MONEY NULL,  
                 Cargos        MONEY NULL,  
                 Abonos        MONEY NULL  
              )  
              
              CREATE TABLE #cont2  
              (  
                 Cuenta        CHAR(20) NULL,  
                 Descripcion   VARCHAR(255) NULL,  
                 Rama          CHAR(20) NULL,  
                 Esacumulativa BIT NULL,  
                 Tipo          CHAR(15) NULL,  
                 Inicio        MONEY NULL,  
                 Cargos        MONEY NULL,  
                 Abonos        MONEY NULL  
              )  
  
    SELECT @Clave=Clave, @Servidor = NULLIF(RTRIM(Servidor), ''), @Base = NULLIF(RTRIM(Base), '')  
    FROM DicoServReportes WHERE Clave='ServidorReportes' AND Empresa=@Empresa  
  
    IF @Clave IS NULL  
  RAISERROR('No está dado de alta el Servidor de Reportes',16,-1)  
  
    IF @Servidor IS NULL  
    SELECT @Servidor=@@SERVERNAME  
      
    IF @Base IS NULL  
    SELECT @Base=DB_NAME()  
      
 SELECT @Servidor = '[' + RTRIM(@Servidor) + ']' + '.'  
 SELECT @BaseT = @Base + '.dbo.'  
  
  IF @Cuenta<>'A'
  BEGIN
 SELECT @Comando=  
            'INSERT INTO #cont  
                        (Cuenta,  
                         Descripcion,  
                         Rama,  
                         Esacumulativa,  
                         Tipo,  
                         Inicio,  
                         Cargos,  
                         Abonos)  
            SELECT aa.Cuenta,  
                   aa.Descripcion,  
                   aa.Rama,  
                   aa.Esacumulativa,  
                   aa.Tipo,  
                   "Inicio" = (SELECT Sum(Isnull(a2.Cargos, 0)) - Sum(  
                                      Isnull(a2.Abonos, 0))  
                               FROM '+ RTRIM(@Servidor) + RTRIM(@BaseT)+ 'Cta ab  WITH(NOLOCK)
                               LEFT   OUTER JOIN ' + RTRIM(@Servidor) + RTRIM(@BaseT)+' Acum a2  WITH(NOLOCK)
                                                   ON ab.Cuenta = a2.Cuenta  
                                                      AND a2.Empresa = "'+RTRIM(LTRIM(@Empresa))+'"  
                                                      AND a2.Rama ="CONT"  
                                                      AND a2.Ejercicio = '+ CAST(@Ejercicio AS VARCHAR)+'  
                                                      AND a2.Periodo BETWEEN 0 AND  '+CAST(@PeriodoAnt AS VARCHAR) +'  
                                                      AND ab.Rama ="'+RTRIM(LTRIM(@Cuenta))+'"  
                                                      AND Isnull(a2.Sucursal,0)=Isnull(Isnull( '+ CASE WHEN @Sucursal IS NULL THEN 'NULL' ELSE CAST(@Sucursal AS Varchar) END    +', a2.Sucursal), 0)  
                                                      AND a2.Moneda = "'+RTRIM(LTRIM(@Moneda))+'"  
             WHERE  aa.Cuenta = ab.Cuenta),  
                   "Cargos" = Sum(Isnull(Acum.Cargos, 0)),  
                   "Abonos" = Sum(Isnull(Acum.Abonos, 0))  
            FROM ' + RTRIM(@Servidor) + RTRIM(@BaseT)+  'Cta aa  WITH(NOLOCK)
                   LEFT OUTER JOIN '+RTRIM(@Servidor) + RTRIM(@BaseT)+  'Acum Acum  WITH(NOLOCK)
                   ON aa.Cuenta = Acum.Cuenta  
                   AND Acum.Empresa = "'+RTRIM(LTRIM(@Empresa))+'"  
                   AND Acum.Rama ="CONT"  
                   AND Acum.Ejercicio = '+ CAST(@Ejercicio AS VARCHAR)+'  
                   AND Acum.Periodo BETWEEN '+CAST(@PeriodoD AS VARCHAR) +' AND '+ CAST(@PeriodoA AS VARCHAR)+'  
                   AND Isnull(Acum.Sucursal, 0) = Isnull(Isnull( '+CASE WHEN @Sucursal IS NULL THEN 'NULL' ELSE CAST(@Sucursal AS Varchar) END+', Acum.Sucursal), 0)  
                   AND Acum.Moneda = "'+RTRIM(LTRIM(@Moneda))+'"  
            WHERE  aa.Rama = "'+RTRIM(LTRIM(@Cuenta))+'"  
            GROUP  BY aa.Cuenta,  
                      aa.Descripcion,  
                      aa.Rama,  
                      aa.Tipo,  
                      aa.Esacumulativa  
            HAVING ( Sum(Isnull(Acum.Cargos, 0.0)) <> 0.0  
                      OR Sum(Isnull(Acum.Abonos, 0.0)) <> 0.0  
                      OR (SELECT Sum(Isnull(a2.Cargos, 0.0)) - Sum(  
                                 Isnull(a2.Abonos, 0.0))  
                          FROM '+RTRIM(@Servidor) + RTRIM(@BaseT)+ 'Cta ab  WITH(NOLOCK)
                          LEFT OUTER JOIN '+RTRIM(@Servidor) + RTRIM(@BaseT)+ 'Acum a2  WITH(NOLOCK)
                                              ON ab.Cuenta = a2.Cuenta  
                                                 AND a2.Empresa = "'+RTRIM(LTRIM(@Empresa))+'"  
                                                 AND a2.Rama ="CONT"  
                                                 AND a2.Ejercicio = '+ CAST(@Ejercicio AS VARCHAR)+'  
                                                 AND a2.Periodo BETWEEN 0 AND  '+CAST(@PeriodoAnt AS VARCHAR)  +'  
       WHERE  ab.Rama =  "'+RTRIM(LTRIM(@Cuenta))+'" AND aa.Cuenta = ab.Cuenta) <> 0.0 )  
            ORDER  BY aa.Cuenta'  
  
  END
  ELSE
  	BEGIN
  		 SELECT @Comando=  
            'INSERT INTO #cont  
                        (Cuenta,  
                         Descripcion,  
                         Rama,  
                         Esacumulativa,  
                         Tipo,  
                         Inicio,  
                         Cargos,  
                         Abonos)  
            SELECT IIF(aa.Cuenta="700-000-000","X",aa.Cuenta) AS "Cuenta",  
                   aa.Descripcion,  
                   aa.Rama,  
                   aa.Esacumulativa,  
                   aa.Tipo,  
                   "Inicio" = (SELECT Sum(Isnull(a2.Cargos, 0)) - Sum(  
                                      Isnull(a2.Abonos, 0))  
                               FROM '+ RTRIM(@Servidor) + RTRIM(@BaseT)+ 'Cta ab  WITH(NOLOCK)
                               LEFT   OUTER JOIN ' + RTRIM(@Servidor) + RTRIM(@BaseT)+' Acum a2  WITH(NOLOCK)
                                                   ON ab.Cuenta = a2.Cuenta  
                                                      AND a2.Empresa = "'+RTRIM(LTRIM(@Empresa))+'"  
                                                      AND a2.Rama ="CONT"  
                                                      AND a2.Ejercicio = '+ CAST(@Ejercicio AS VARCHAR)+'  
                                                      AND a2.Periodo BETWEEN 0 AND  '+CAST(@PeriodoAnt AS VARCHAR) +'  
                                                      AND ab.Grupo="TST"  
                                                      AND Isnull(a2.Sucursal,0)=Isnull(Isnull( '+ CASE WHEN @Sucursal IS NULL THEN 'NULL' ELSE CAST(@Sucursal AS Varchar) END    +', a2.Sucursal), 0)  
                                                      AND a2.Moneda = "'+RTRIM(LTRIM(@Moneda))+'"  
             WHERE  aa.Cuenta = ab.Cuenta),  
                   "Cargos" = Sum(Isnull(Acum.Cargos, 0)),  
                   "Abonos" = Sum(Isnull(Acum.Abonos, 0))  
            FROM ' + RTRIM(@Servidor) + RTRIM(@BaseT)+  'Cta aa  WITH(NOLOCK)
                   LEFT OUTER JOIN '+RTRIM(@Servidor) + RTRIM(@BaseT)+  'Acum Acum  WITH(NOLOCK)
                   ON aa.Cuenta = Acum.Cuenta  
                   AND Acum.Empresa = "'+RTRIM(LTRIM(@Empresa))+'"  
                   AND Acum.Rama ="CONT"  
                   AND Acum.Ejercicio = '+ CAST(@Ejercicio AS VARCHAR)+'  
                   AND Acum.Periodo BETWEEN '+CAST(@PeriodoD AS VARCHAR) +' AND '+ CAST(@PeriodoA AS VARCHAR)+'  
                   AND Isnull(Acum.Sucursal, 0) = Isnull(Isnull( '+CASE WHEN @Sucursal IS NULL THEN 'NULL' ELSE CAST(@Sucursal AS Varchar) END+', Acum.Sucursal), 0)  
                   AND Acum.Moneda = "'+RTRIM(LTRIM(@Moneda))+'"  
            WHERE  aa.Grupo="TST"  
            GROUP  BY aa.Cuenta,  
                      aa.Descripcion,  
                      aa.Rama,  
                      aa.Tipo,  
                      aa.Esacumulativa  
            HAVING ( Sum(Isnull(Acum.Cargos, 0.0)) <> 0.0  
                      OR Sum(Isnull(Acum.Abonos, 0.0)) <> 0.0  
                      OR (SELECT Sum(Isnull(a2.Cargos, 0.0)) - Sum(  
                                 Isnull(a2.Abonos, 0.0))  
                          FROM '+RTRIM(@Servidor) + RTRIM(@BaseT)+ 'Cta ab  WITH(NOLOCK)
                          LEFT OUTER JOIN '+RTRIM(@Servidor) + RTRIM(@BaseT)+ 'Acum a2  WITH(NOLOCK)
                                              ON ab.Cuenta = a2.Cuenta  
                                                 AND a2.Empresa = "'+RTRIM(LTRIM(@Empresa))+'"  
                                                 AND a2.Rama ="CONT"  
                                                 AND a2.Ejercicio = '+ CAST(@Ejercicio AS VARCHAR)+'  
                                                 AND a2.Periodo BETWEEN 0 AND  '+CAST(@PeriodoAnt AS VARCHAR)  +'  
       WHERE  ab.Grupo="TST" AND aa.Cuenta = ab.Cuenta) <> 0.0 )  
            ORDER  BY Cuenta'  
  
  	END
  	
  	
 EXEC (@Comando)  
            
    IF @Cuenta <> 'A'
    BEGIN
            INSERT INTO #cont  
                        (Cuenta,  
                         Descripcion,  
                         Rama,  
                         Esacumulativa,  
                         Tipo,  
                         Inicio,  
                         Cargos,  
                         Abonos)  
            SELECT NULL,  
                   'Totales',  
                   NULL,  
                   NULL,  
                   NULL,  
                   Sum(Isnull(Inicio, 0)),  
                   Sum(Isnull(Cargos, 0)),  
                   Sum(Isnull(Abonos, 0))  
            FROM   #cont  
  
            SELECT *  
            FROM   #cont  
    END
    ELSE
    	BEGIN
    		INSERT INTO #cont2  
                        (Cuenta,  
                         Descripcion,  
                         Rama,  
                         Esacumulativa,  
                         Tipo,  
                         Inicio,  
                         Cargos,  
                         Abonos)  
              SELECT Cuenta,  
                         Descripcion,  
                         Rama,  
                         Esacumulativa,  
                         Tipo,  
                         Inicio,  
                         Cargos,  
                         Abonos
              FROM #cont AS c 
              WHERE c.Cuenta <> 'X'
              
              INSERT INTO #cont2  
                        (Cuenta,  
                         Descripcion,  
                         Rama,  
                         Esacumulativa,  
                         Tipo,  
                         Inicio,  
                         Cargos,  
                         Abonos)  
              SELECT Cuenta,  
                         Descripcion,  
                         Rama,  
                         Esacumulativa,  
                         Tipo,  
                         Inicio,  
                         Cargos,  
                         Abonos
              FROM #cont AS c 
              WHERE c.Cuenta = 'X'
                
              
              INSERT INTO #cont2 
                        (Cuenta,  
                         Descripcion,  
                         Rama,  
                         Esacumulativa,  
                         Tipo,  
                         Inicio,  
                         Cargos,  
                         Abonos)  
            SELECT NULL,  
                   'Totales',  
                   NULL,  
                   NULL,  
                   NULL,  
                   Sum(Isnull(Inicio, 0)),  
                   Sum(Isnull(Cargos, 0)),  
                   Sum(Isnull(Abonos, 0))  
            FROM   #cont  
  
            SELECT *  
            FROM   #cont2 
                      
    	END
        END  
  END   