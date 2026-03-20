--- Crear tabla Raw tabla reslpaldo

CREATE TABLE raw_produccion (
    Date TEXT,
    Department TEXT,
    Municipality TEXT,
    Operator TEXT,
    Field TEXT,
    Contract TEXT,
    Country TEXT,
    Oil_barrels_per_day TEXT
);


--- Cargar archivo CSV a la tabla RAW

COPY raw_produccion FROM 'C:\Crude Oil Production\Crude Oil Production.csv' HEADER CSV DELIMITER ';';


-- Se renombro la tabla Staging

-- Crear tabla Staging

CREATE TABLE stg_oilproduction (
    fecha DATE,
    Department TEXT,
    Municipality TEXT,
    Operator TEXT,
    Field TEXT,
    Contract TEXT,
    Country TEXT,
    Oil_barrels_per_day NUMERIC
);

---Pegar la tabla raw a staging

INSERT INTO stg_oilproduction 
    SELECT 
    TO_DATE(fecha,'yyyy-dd-mm'),
    Department,
    Municipality,
    Operator,
    Field,
    Contract,
    Country,
    NULLIF (Oil_barrels_per_day,'')::NUMERIC
FROM raw_oilproduction;
 
 ----Validar campo oil_barrels_per_day


UPDATE stg_oilproduction
SET Oil_barrels_per_day = 
  CASE 
    WHEN Oil_barrels_per_day::TEXT ~ '^[0-9]+(\.[0-9]+)?$'
    THEN Oil_barrels_per_day::NUMERIC
    ELSE NULL
  END;


----- CREACION DE MODELO ESTRALLA

--- Tabla fact Metricas
--- Dimensiones 

---- Tabla dim fechas

CREATE TABLE dim_fecha (
  fecha_id SERIAL PRIMARY KEY,
  fecha DATE,
  año INT,
  mes INT,
  dia INT
);

-- Insertar tablas dim_fechas

INSERT INTO dim_fecha (fecha, anio, mes, dia)
SELECT DISTINCT
  fecha,
  EXTRACT(YEAR FROM fecha),
  EXTRACT(MONTH FROM fecha),
  EXTRACT(DAY FROM fecha)
FROM stg_produccion;

---- Crear Tabla dim campo

CREATE TABLE dim_campo (
  campo_id SERIAL PRIMARY KEY,
  campo VARCHAR(100)
);

---Insertar datos en dim_Campo

INSERT INTO dim_campo (campo)
SELECT DISTINCT TRIM(field)
FROM stg_oilproduction
WHERE field IS NOT NULL;


-- Crear tabla dim_operador

CREATE TABLE dim_operador (
  operador_id SERIAL PRIMARY KEY,
  operador VARCHAR(100)
);

INSERT INTO dim_operador (operador)
SELECT DISTINCT TRIM(operator)
FROM stg_produccion;

-- Crear tabla dim_ubicacion

CREATE TABLE dim_ubicacion (
  ubicacion_id SERIAL PRIMARY KEY,
  pais VARCHAR(50),
  departamento VARCHAR(100),
  municipio VARCHAR(100)
);

INSERT INTO dim_ubicacion (pais, departamento, municipio)
SELECT DISTINCT
  TRIM(country),
  TRIM(department),
  TRIM(municipality)
FROM stg_oilproduction
WHERE country IS NOT NULL;


--Creacion de tabla contrato

CREATE TABLE dim_contrato(
contrato_id SERIAL PRIMARY KEY,
contrato VARCHAR(50)
);

CREATE TABLE dim_contrato(
contrato_id SERIAL PRIMARY KEY,
contrato VARCHAR(50)
);

INSERT INTO dim_contrato(contrato)
SELECT DISTINCT UPPER(TRIM(contract)
)

FROM stg_oilproduction
WHERE contract IS NOT NULL;

--- Crear tabla fact

CREATE TABLE fact_oilproduction (
    id_fact SERIAL PRIMARY KEY,
    fecha_id INT REFERENCES dim_fecha(fecha_id),
    ubicacion_id INT REFERENCES dim_ubicacion(ubicacion_id),
    operador_id INT REFERENCES dim_operador(operador_id),
    campo_id INT REFERENCES dim_campo(campo_id),
    contrato_id INT REFERENCES dim_campo(contrato_id),

    oil_barrels_per_day NUMERIC
);

--- Se creo la tabla hecho  --- Insertar datos


INSERT INTO fact_oilproduction (fecha_id, ubicacion_id, operador_id, campo_id, contrato_id, oil_barrels_per_day)
SELECT 
    f.fecha_id,
    u.ubicacion_id,
    o.operador_id,
    c.campo_id,
    ct.contrato_id,
    s.Oil_barrels_per_day
FROM stg_oilproduction s
JOIN dim_fecha f 
    ON s.fecha = f.fecha
JOIN dim_ubicacion u 
    ON s.department = u.departamento
   AND s.municipality = u.municipio
   AND s.country = u.pais
JOIN dim_operador o 
    ON s.operator = o.operador
JOIN dim_campo c
    ON s.field = c.campo
JOIN dim_contrato ct
    ON s.contract = ct.contrato;
    

    
