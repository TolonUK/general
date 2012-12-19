CREATE OR REPLACE PACKAGE BODY pg_user_geom_util AS
-- copyright (c) 2012, Nicander Ltd

-- Gets the next token in a separated list. See StringToGeom for an example.
PROCEDURE get_token( iStart   IN NUMBER,
           sPattern in VARCHAR2,
           sBuffer  in VARCHAR2,
           sResult  OUT NOCOPY VARCHAR2,
           iNextPos OUT NOCOPY NUMBER ) IS
  nPos1 number;
  nPos2 number;
BEGIN
  nPos1 := Instr(sBuffer, sPattern, iStart);
  IF nPos1 = 0 then
  sResult := rtrim(ltrim(substr(sBuffer, iStart, LENGTH(sBuffer) - iStart)));
  ELSE
  sResult  := Rtrim(Ltrim(Substr(sBuffer, iStart, nPos1 - iStart)));
  iNextPos := nPos1 + 1;
  END IF;
END;

--------------------------------------------------------------------------------
  
FUNCTION NumberToString(pNumber IN NUMBER) RETURN VARCHAR2 IS
BEGIN
  IF (pNumber IS NULL) THEN
    RETURN 'NULL';
  ELSE
    RETURN TO_CHAR(pNumber);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    --DBMS_OUTPUT.PUT_LINE('Exception caught: ' || DBMS_UTILITY.FORMAT_ERROR_STACK() || ', ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE());
    RETURN 'NULL';
END;
  
--------------------------------------------------------------------------------
  
FUNCTION StringToNumber(pString IN VARCHAR2) RETURN NUMBER IS
BEGIN
    RETURN TO_NUMBER(pString);
EXCEPTION
  WHEN OTHERS THEN
    --DBMS_OUTPUT.PUT_LINE('Exception caught: ' || DBMS_UTILITY.FORMAT_ERROR_STACK() || ', ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE());
    RETURN NULL;
END;
  
--------------------------------------------------------------------------------
  
  -- String format is as follows:
  --
  -- <GTYPE>,<SRID>,<POINT>,<ELEM_INFO>,<ORDINATES>
  --
  -- Where:
  -- <GTYPE> := <OPTIONAL_NUMBER>
  -- <SRID> := <OPTIONAL_NUMBER>
  -- <POINT> := NULL | SDO_POINT_TYPE, OPTIONAL_NUMBER, OPTIONAL_NUMBER, OPTIONAL_NUMBER
  -- <ELEM_INFO> := NULL | SDO_ELEM_INFO_ARRAY, NUMBER, {OPTIONAL_NUMBER, ...}
  -- <ORDINATES> := NULL | SDO_ORDINATE_ARRAY, NUMBER, {OPTIONAL_NUMBER, ...}
  --
  -- <OPTIONAL_NUMBER> := NULL | NUMBER
  -- entries in curly braces are repeated from n times
FUNCTION GeomToString(pGeom IN mdsys.sdo_geometry ) RETURN VARCHAR2 DETERMINISTIC IS
  vString VARCHAR(32767);
  vCount NUMBER;
BEGIN
  -- GTYPE
  vString := NumberToString(pGeom.SDO_GTYPE);
  
  -- SRID
  vString := vString || ',' || NumberToString(pGeom.SDO_SRID);
  
  -- POINT
  IF (pGeom.SDO_POINT IS NULL) THEN
    vString := vString || ',NULL';
  ELSE
    vString := vString || ',SDO_POINT_TYPE,' || NumberToString(pGeom.SDO_POINT.X) || ',' || NumberToString(pGeom.SDO_POINT.Y) || ',' || NumberToString(pGeom.SDO_POINT.Z);
  END IF;
  
  -- ELEM_INFO
  IF (pGeom.SDO_ELEM_INFO IS NULL) THEN
    vString := vString || ',NULL';
  ELSE
    vCount := pGeom.SDO_ELEM_INFO.COUNT;
    vString := vString || ',SDO_ELEM_INFO_ARRAY,' || vCount;
    FOR i IN 1..vCount LOOP
      vString := vString || ',' || NumberToString(pGeom.SDO_ELEM_INFO(i));
    END LOOP;
  END IF;
  
  -- ORDINATES
  IF (pGeom.SDO_ORDINATES IS NULL) THEN
    vString := vString || ',NULL';
  ELSE
    vCount := pGeom.SDO_ORDINATES.COUNT;
    vString := vString || ',SDO_ORDINATE_ARRAY,' || vCount;
    FOR i IN 1..vCount LOOP
      vString := vString || ',' || NumberToString(pGeom.SDO_ORDINATES(i));
    END LOOP;
  END IF;
  
  RETURN vString;
END;
  
--------------------------------------------------------------------------------
  
PROCEDURE Test_GeomToString IS
  vGeom MDSYS.SDO_GEOMETRY;
  vString VARCHAR2(32767);
BEGIN
  -- TEST CASE 1 - POINT
  dbms_output.put_line('----- TEST CASE 1 -----');
  vGeom := mdsys.sdo_geometry( 2001, NULL, MDSYS.SDO_POINT_TYPE(12345, 67890, NULL), null, null );
  dbms_output.put_line('Src Geom: ' || SDO_UTIL.TO_WKTGEOMETRY(vGeom));
  vString := GeomToString(vGeom);
  IF (vString IS NULL) THEN
    vString := '<NULL>';
  END IF;
  dbms_output.put_line('Dest String: ' || vString);
  
  -- TEST CASE 2 - LINE
  dbms_output.put_line('----- TEST CASE 2 -----');
  vGeom := MDSYS.SDO_GEOMETRY(2002,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),MDSYS.SDO_ORDINATE_ARRAY(652737.95,6589964.213,652741.222,6589983.148,652746.77,6590018.745,652752.029,6590050.2,652759.351,6590085.732));
  dbms_output.put_line('Src Geom: ' || SDO_UTIL.TO_WKTGEOMETRY(vGeom));
  vString := GeomToString(vGeom);
  IF (vString IS NULL) THEN
    vString := '<NULL>';
  END IF;
  dbms_output.put_line('Dest String: ' || vString);
END;
  
--------------------------------------------------------------------------------
  
FUNCTION StringToGeom(pString IN VARCHAR2) RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC IS
  vGeom MDSYS.SDO_GEOMETRY;
  vPos NUMBER := 1;
  vNextPos NUMBER := 1;
  vToken VARCHAR2(32767);
  vSep CONSTANT VARCHAR2(2) := ',';
  vCount NUMBER;
BEGIN
  vGeom := MDSYS.SDO_GEOMETRY('POINT(0 0)');
  
  -- GTYPE
  get_token(vPos, vSep, pString, vToken, vNextPos); vPos := vNextPos;
  vGeom.SDO_GTYPE := StringToNumber(vToken);
  
  -- SRID
  get_token(vPos, vSep, pString, vToken, vNextPos); vPos := vNextPos;
  vGeom.SDO_SRID := StringToNumber(vToken);
  
  -- POINT
  get_token(vPos, vSep, pString, vToken, vNextPos); vPos := vNextPos;
  IF (UPPER(vToken) LIKE 'SDO_POINT_TYPE') THEN
    vGeom.SDO_POINT := MDSYS.SDO_POINT_TYPE(NULL, NULL, NULL);
    get_token(vPos, vSep, pString, vToken, vNextPos); vPos := vNextPos;
    vGeom.SDO_POINT.X := StringToNumber(vToken);
    get_token(vPos, vSep, pString, vToken, vNextPos); vPos := vNextPos;
    vGeom.SDO_POINT.Y := StringToNumber(vToken);
    get_token(vPos, vSep, pString, vToken, vNextPos); vPos := vNextPos;
    vGeom.SDO_POINT.Z := StringToNumber(vToken);
  ELSE
    vGeom.SDO_POINT := NULL;
  END IF;
  
  -- ELEM_INFO
  get_token(vPos, vSep, pString, vToken, vNextPos); vPos := vNextPos;
  IF (UPPER(vToken) LIKE 'SDO_ELEM_INFO_ARRAY') THEN
    vGeom.SDO_ELEM_INFO := MDSYS.SDO_ELEM_INFO_ARRAY();
    get_token(vPos, vSep, pString, vToken, vNextPos); vPos := vNextPos;
    vCount := StringToNumber(vToken);
    IF (vCount > 0) THEN
      vGeom.SDO_ELEM_INFO.EXTEND(vCount);
      FOR i IN 1..vCount LOOP
        get_token(vPos, vSep, pString, vToken, vNextPos); vPos := vNextPos;
        vGeom.SDO_ELEM_INFO(i) := StringToNumber(vToken);
      END LOOP;
    END IF;
  ELSE
    vGeom.SDO_ELEM_INFO := NULL;
  END IF;
  
  -- ORDINATES
  get_token(vPos, vSep, pString, vToken, vNextPos); vPos := vNextPos;
  IF (UPPER(vToken) LIKE 'SDO_ORDINATE_ARRAY') THEN
    vGeom.SDO_ORDINATES := MDSYS.SDO_ORDINATE_ARRAY();
    get_token(vPos, vSep, pString, vToken, vNextPos); vPos := vNextPos;
    vCount := StringToNumber(vToken);
    IF (vCount > 0) THEN
      vGeom.SDO_ORDINATES.EXTEND(vCount);
      FOR i IN 1..vCount LOOP
        get_token(vPos, vSep, pString, vToken, vNextPos); vPos := vNextPos;
        vGeom.SDO_ORDINATES(i) := StringToNumber(vToken);
      END LOOP;
    END IF;
  ELSE
    vGeom.SDO_ORDINATES := NULL;
  END IF;

  RETURN vGeom;
END;
  
--------------------------------------------------------------------------------
  
PROCEDURE Test_StringToGeom IS
  vString VARCHAR2(32767);
  vGeom MDSYS.SDO_GEOMETRY;
BEGIN
  -- TEST CASE 1 - POINT
  dbms_output.put_line('----- TEST CASE 1 -----');
  vString := '2001,NULL,SDO_POINT_TYPE,12345,67890,NULL,NULL,NULL';
  dbms_output.put_line('src string: ' || vString);
  vGeom := StringToGeom(vString);
  dbms_output.put_line('dest geom: ' || SDO_UTIL.TO_WKTGEOMETRY(vGeom));

  -- TEST CASE 2 - LINE
  dbms_output.put_line('----- TEST CASE 2 -----');
  vString := '2002,NULL,NULL,SDO_ELEM_INFO_ARRAY,3,1,2,1,SDO_ORDINATE_ARRAY,10,652737.95,6589964.213,652741.222,6589983.148,652746.77,6590018.745,652752.029,6590050.2,652759.351,6590085.732';
  dbms_output.put_line('src string: ' || vString);
  vGeom := StringToGeom(vString);
  dbms_output.put_line('dest geom: ' || SDO_UTIL.TO_WKTGEOMETRY(vGeom));
END;

--------------------------------------------------------------------------------

PROCEDURE PerfTest_GeomStrings(pGeomCount IN INTEGER, pGeomVertexCount IN INTEGER) IS
  TYPE geom_array IS VARRAY(1000) OF MDSYS.SDO_GEOMETRY;
  vGeoms geom_array := geom_array();
  vWKTGeoms geom_array := geom_array();
  vGMLGeoms geom_array := geom_array();
  vCustomGeoms geom_array := geom_array();
  TYPE string_array IS VARRAY(1000) OF VARCHAR2(32767);
  vWkts string_array := string_array();
  vGmls string_array := string_array();
  vCustoms string_array := string_array();
  vWktStart timestamp;
  vWktEncDelta interval day to second;
  vWktDecDelta interval day to second;
  vGmlStart timestamp;
  vGmlEncDelta interval day to second;
  vGmlDecDelta interval day to second;
  vCustomStart timestamp;
  vCustomEncDelta interval day to second;
  vCustomDecDelta interval day to second;
  vTempOrdinates MDSYS.SDO_ORDINATE_ARRAY;
BEGIN
  dbms_output.put_line('----- ' || pGeomCount || ' geometries with ' || pGeomVertexCount || ' vertices -----');

  vGeoms.extend(pGeomCount);
  vWKTGeoms.extend(pGeomCount);
  vGMLGeoms.extend(pGeomCount);
  vCustomGeoms.extend(pGeomCount);
  vWkts.extend(pGeomCount);
  vGmls.extend(pGeomCount);
  vCustoms.extend(pGeomCount);
  
  FOR i IN 1..pGeomCount LOOP
    vTempOrdinates := MDSYS.SDO_ORDINATE_ARRAY();
    vTempOrdinates.extend(pGeomVertexCount*2);
    FOR j IN 1..(pGeomVertexCount*2) LOOP
      vTempOrdinates(j) := i + j;
    END LOOP;
    vGeoms(i) := mdsys.sdo_geometry(2002, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1), vTempOrdinates);
  END LOOP;
  
  -- encode to WKT
  vWktStart := systimestamp;
  FOR i IN 1..pGeomCount LOOP
    vWkts(i) := SDO_UTIL.TO_WKTGEOMETRY(vGeoms(i));
  END LOOP;
  vWktEncDelta := systimestamp - vWktStart;
  
  -- encode to GML
  vGmlStart := systimestamp;
  FOR i IN 1..pGeomCount LOOP
    vGmls(i) := SDO_UTIL.TO_GMLGEOMETRY(vGeoms(i));
  END LOOP;
  vGmlEncDelta := systimestamp - vGmlStart;
  
  -- encode to custom
  vCustomStart := systimestamp;
  FOR i IN 1..pGeomCount LOOP
    vCustoms(i) := GeomToString(vGeoms(i));
  END LOOP;
  vCustomEncDelta := systimestamp - vCustomStart;
  
  -- decode from WKT
  vWktStart := systimestamp;
  FOR i IN 1..pGeomCount LOOP
    vWKTGeoms(i) := SDO_UTIL.FROM_WKTGEOMETRY(vWkts(i));
  END LOOP;
  vWktDecDelta := systimestamp - vWktStart;
  
  -- decode from GML
  vGmlStart := systimestamp;
  FOR i IN 1..pGeomCount LOOP
    vGMLGeoms(i) := SDO_UTIL.FROM_GMLGEOMETRY(vGMLs(i));
  END LOOP;
  vGmlDecDelta := systimestamp - vGmlStart;
  
  -- decode from custom
  vCustomStart := systimestamp;
  FOR i IN 1..pGeomCount LOOP
    vCustomGeoms(i) := StringToGeom(vCustoms(i));
  END LOOP;
  vCustomDecDelta := systimestamp - vCustomStart;
  
  dbms_output.put_line('Encoding to WKT took ' || extract(second from vWktEncDelta) || ' seconds');
  dbms_output.put_line('Encoding to GML took ' || extract(second from vGmlEncDelta) || ' seconds');
  dbms_output.put_line('Encoding to custom took ' || extract(second from vCustomEncDelta) || ' seconds');
  
  dbms_output.put_line('Decoding from WKT took ' || extract(second from vWktDecDelta) || ' seconds');
  dbms_output.put_line('Decoding from GML took ' || extract(second from vGmlDecDelta) || ' seconds');
  dbms_output.put_line('Decoding from custom took ' || extract(second from vCustomDecDelta) || ' seconds');
  
  dbms_output.put_line('----------------------------------------');
  dbms_output.put_line(' ');
END;

--------------------------------------------------------------------------------

PROCEDURE PerfTest_GeomStrings IS
BEGIN
  -- geometries with 2 vertices
  PerfTest_GeomStrings(1, 2);
  PerfTest_GeomStrings(10, 2);
  PerfTest_GeomStrings(100, 2);
  PerfTest_GeomStrings(1000, 2);
  
  -- geometries with 10 vertices
  PerfTest_GeomStrings(1, 10);
  PerfTest_GeomStrings(10, 10);
  PerfTest_GeomStrings(100, 10);
  PerfTest_GeomStrings(1000, 10);

  -- geometries with 100 vertices
  PerfTest_GeomStrings(1, 100);
  PerfTest_GeomStrings(10, 100);
  PerfTest_GeomStrings(100, 100);
  PerfTest_GeomStrings(1000, 100);

  -- geometries with 1000 vertices
  PerfTest_GeomStrings(1, 1000);
  PerfTest_GeomStrings(10, 1000);
  PerfTest_GeomStrings(100, 1000);
  PerfTest_GeomStrings(1000, 1000);

END;

END pg_user_geom_util;
/

show errors package body pg_user_geom_util;
