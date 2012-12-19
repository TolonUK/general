CREATE OR REPLACE PACKAGE pg_user_geom_util AS
-- copyright (c) 2012, Nicander Ltd
	
	-- Translates a geometry object into a string representation 
	-- for storage and transport. See also StringToGeom.
	FUNCTION GeomToString(pGeom IN mdsys.sdo_geometry ) RETURN VARCHAR2 DETERMINISTIC;
	PROCEDURE Test_GeomToString;
	
	-- Translate a geometry string representation into a geometry object.
	-- See also GeomToString.
	FUNCTION StringToGeom(pString IN VARCHAR2) RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
	PROCEDURE Test_StringToGeom;
	
	-- Tests the conversion between sdo_geometry objects and a string representation.
	-- Tests for pGeomCount geometries, each with pGeomVertexCount vertices.
	PROCEDURE PerfTest_GeomStrings(pGeomCount IN INTEGER, pGeomVertexCount IN INTEGER);
	
	-- Runs PerfTest_GeomStrings(INTEGER, INTEGER) for a selection of values.
	PROCEDURE PerfTest_GeomStrings;
	
END pg_user_geom_util;
/

show errors package pg_user_geom_util;
