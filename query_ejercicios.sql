-- Problema A:
SELECT E.NOMBRE_EMPRESA, T.NOMBRE_TRABAJADOR, COUNT(L.ID_LICENCIA_MEDICA) AS cantidad_licencias
FROM TBL_LICENCIA_MEDICA L
         INNER JOIN TBL_TRABAJADOR T ON L.ID_TRABAJADOR_EMPRESA = T.ID_TRABAJADOR
         INNER JOIN REL_TRABAJADOR_EMPRESA TE ON T.ID_TRABAJADOR = TE.ID_TRABAJADOR
         INNER JOIN TBL_EMPRESA E ON TE.ID_EMPRESA = E.ID_EMPRESA
WHERE L.CODIGO_ENFERMEDAD = 123 --Este codigo utilice simulando que seria el de COVID
  AND GETDATE() BETWEEN TE.FECHA_INICIO_CONTRATO AND TE.FECHA_FIN_CONTRATO
GROUP BY E.NOMBRE_EMPRESA, T.NOMBRE_TRABAJADOR;

--Problema B:
SELECT E.RUT_EMPRESA, E.NOMBRE_EMPRESA
FROM TBL_EMPRESA E
         LEFT JOIN REL_TRABAJADOR_EMPRESA TE ON E.ID_EMPRESA = TE.ID_EMPRESA
         LEFT JOIN TBL_LICENCIA_MEDICA L ON TE.ID_TRABAJADOR_EMPRESA = L.ID_TRABAJADOR_EMPRESA
WHERE TE.ID_TRABAJADOR_EMPRESA IS NULL
   OR L.ID_LICENCIA_MEDICA IS NOT NULL
GROUP BY E.RUT_EMPRESA, E.NOMBRE_EMPRESA;

--Problema C:
SELECT E.NOMBRE_EMPRESA,
       YEAR(L.FECHA_INICIO)        AS Anio,
       COUNT(L.ID_LICENCIA_MEDICA) AS cantidad_licencias,
       SUM(L.MONTO_REEMBOLSO)      AS monto_reembolsado
FROM TBL_EMPRESA E
         LEFT JOIN
     REL_TRABAJADOR_EMPRESA TE ON E.ID_EMPRESA = TE.ID_EMPRESA
         LEFT JOIN
     TBL_LICENCIA_MEDICA L ON TE.ID_TRABAJADOR_EMPRESA = L.ID_TRABAJADOR_EMPRESA
WHERE YEAR(L.FECHA_INICIO) >= 2015
GROUP BY E.NOMBRE_EMPRESA,
         YEAR(L.FECHA_INICIO);

--Problema D:
SELECT T.RUT_TRABAJADOR, T.NOMBRE_TRABAJADOR, COUNT(L.ID_LICENCIA_MEDICA) AS cantidad_licencias
FROM TBL_TRABAJADOR T
         INNER JOIN REL_TRABAJADOR_EMPRESA TE ON T.ID_TRABAJADOR = TE.ID_TRABAJADOR
         INNER JOIN TBL_LICENCIA_MEDICA L ON TE.ID_TRABAJADOR_EMPRESA = L.ID_TRABAJADOR_EMPRESA
WHERE YEAR(L.FECHA_INICIO) = YEAR(GETDATE())                               -- Licencias médicas del año actual
  AND GETDATE() BETWEEN TE.FECHA_INICIO_CONTRATO AND TE.FECHA_FIN_CONTRATO -- Contrato vigente
GROUP BY T.RUT_TRABAJADOR, T.NOMBRE_TRABAJADOR
HAVING COUNT(L.ID_LICENCIA_MEDICA) >=
       DATEDIFF(MONTH, MIN(TE.FECHA_INICIO_CONTRATO), GETDATE()) + 1;

--Problema E:
SELECT E.RUT_EMPRESA,
       E.NOMBRE_EMPRESA,
       AVG(CAST(CASE WHEN ISNUMERIC(M.VALUE) = 1 THEN M.VALUE ELSE NULL END AS DECIMAL)) AS promedio_rentas
FROM TBL_EMPRESA E
         LEFT JOIN REL_TRABAJADOR_EMPRESA TE ON E.ID_EMPRESA = TE.ID_EMPRESA
         LEFT JOIN TBL_LICENCIA_MEDICA L ON TE.ID_TRABAJADOR_EMPRESA = L.ID_TRABAJADOR_EMPRESA
         LEFT JOIN TBL_METADATOS M ON L.ID_LICENCIA_MEDICA = M.ID_LICENCIA_MEDICA AND M.[KEY] LIKE 'renta%'
WHERE ISNUMERIC(M.VALUE) = 1
GROUP BY E.RUT_EMPRESA, E.NOMBRE_EMPRESA;

--Problema F:
WITH TrabajadoresConPosicion AS (SELECT E.NOMBRE_EMPRESA,
                                        T.RUT_TRABAJADOR,
                                        T.NOMBRE_TRABAJADOR,
                                        L.MONTO_REEMBOLSO,
                                        ROW_NUMBER() OVER (PARTITION BY E.ID_EMPRESA ORDER BY L.MONTO_REEMBOLSO DESC) AS POSICION
                                 FROM TBL_EMPRESA E
                                          INNER JOIN REL_TRABAJADOR_EMPRESA TE ON E.ID_EMPRESA = TE.ID_EMPRESA
                                          INNER JOIN TBL_TRABAJADOR T ON TE.ID_TRABAJADOR = T.ID_TRABAJADOR
                                          INNER JOIN TBL_LICENCIA_MEDICA L
                                                     ON TE.ID_TRABAJADOR_EMPRESA = L.ID_TRABAJADOR_EMPRESA)
SELECT NOMBRE_EMPRESA,
       RUT_TRABAJADOR,
       NOMBRE_TRABAJADOR,
       MONTO_REEMBOLSO,
       POSICION
FROM TrabajadoresConPosicion
WHERE POSICION <= 3;

--Problema G:

WITH TrabajadoresLicencia AS (SELECT T.RUT_TRABAJADOR,
                                     T.NOMBRE_TRABAJADOR,
                                     LM.MONTO_REEMBOLSO,
                                     M.[KEY],
                                     M.VALUE,
                                     ROW_NUMBER() OVER (PARTITION BY T.ID_TRABAJADOR, LM.ID_LICENCIA_MEDICA ORDER BY M.[KEY]) AS RowNum
                              FROM TBL_TRABAJADOR T
                                       INNER JOIN REL_TRABAJADOR_EMPRESA TE ON T.ID_TRABAJADOR = TE.ID_TRABAJADOR
                                       INNER JOIN TBL_LICENCIA_MEDICA LM
                                                  ON TE.ID_TRABAJADOR_EMPRESA = LM.ID_TRABAJADOR_EMPRESA
                                       LEFT JOIN TBL_METADATOS M ON LM.ID_LICENCIA_MEDICA = M.ID_LICENCIA_MEDICA
                              WHERE LM.FECHA_FIN >= '2023-08-15' -- Coloque esta fecha para arrojar resultados ya que si colocamos la fecha actual no arrojaria ninguna licencia vigente
)
SELECT RUT_TRABAJADOR,
       NOMBRE_TRABAJADOR,
       MONTO_REEMBOLSO,
       MAX(CASE WHEN RowNum = 1 THEN VALUE END) AS renta1,
       MAX(CASE WHEN RowNum = 2 THEN VALUE END) AS renta2,
       MAX(CASE WHEN RowNum = 3 THEN VALUE END) AS renta3
FROM TrabajadoresLicencia
GROUP BY RUT_TRABAJADOR,
         NOMBRE_TRABAJADOR,
         MONTO_REEMBOLSO
ORDER BY MONTO_REEMBOLSO DESC;














