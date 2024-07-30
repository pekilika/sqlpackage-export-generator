/*
SELECT DB_NAME()
SELECT @@SERVERNAME
*/
	/* user parameters */
	DECLARE @servername NVARCHAR(500) = '';
	DECLARE @datbasename  NVARCHAR(50) = DB_NAME();
	DECLARE @userid NVARCHAR(50) = '';
	DECLARE @password NVARCHAR(50) = '';
	DECLARE @path NVARCHAR(500) = '';

	/* parameters */
	DECLARE @table_inclusions TABLE ( TableName nvarchar(500) );
	DECLARE @table_exclusions TABLE ( TableName nvarchar(500) );
	DECLARE @schema_inclusions TABLE ( SchemaName nvarchar(500) );
	DECLARE @schema_exclusions TABLE ( SchemaName nvarchar(500) );
	DECLARE @powershell TABLE ( RowID INT NOT NULL IDENTITY, Line NVARCHAR(MAX) );

	-- INSERT @schema_inclusions (SchemaName) VALUES ('')
	-- INSERT @table_inclusions (TableName) VALUES ('')
	-- INSERT @table_exclusions (TableName) VALUES  ('')
	-- INSERT @schema_exclusions (SchemaName) VALUES ('')

	INSERT @powershell ( Line ) VALUES ( '$dt = Get-Date -format "yyyyMMddHHmmss"');
	INSERT @powershell ( Line ) VALUES ( '$params = ' );
	INSERT @powershell ( Line ) VALUES ( '"/a:Export",' );
	INSERT @powershell ( Line ) VALUES (
	CONCAT('"/scs:""Server=tcp:', @servername, ',1433;Initial Catalog=', @datbasename,';Persist Security Info=False;User ID=', @userid,';Password=', @password, ';MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Application Name=BacItUp;""",' )
	);
	INSERT @powershell ( Line ) VALUES (
	CONCAT( '"/tf:""', @path, '\$dt', '.', @datbasename, '.bacpac""",' ));

	IF NOT EXISTS( SELECT 1 FROM @table_inclusions )
	BEGIN

		INSERT @table_inclusions (TableName)
		SELECT DISTINCT t.TABLE_NAME
		FROM INFORMATION_SCHEMA.TABLES t
		WHERE t.TABLE_TYPE = 'BASE TABLE'
		ORDER BY t.TABLE_NAME;
    
	END

	IF NOT EXISTS( SELECT 1 FROM @schema_inclusions )
	BEGIN

		INSERT @schema_inclusions (SchemaName)
		SELECT DISTINCT t.TABLE_SCHEMA
		FROM INFORMATION_SCHEMA.TABLES t
		WHERE t.TABLE_TYPE = 'BASE TABLE'
		ORDER BY t.TABLE_SCHEMA;
    
	END
    
	INSERT @powershell ( Line )
	SELECT CONCAT('"/p:""TableData=', QUOTENAME( t.TABLE_SCHEMA ), '.', QUOTENAME(t.TABLE_NAME) ,'""",' )
	FROM INFORMATION_SCHEMA.TABLES t
	WHERE 
		( t.TABLE_NAME IN ( SELECT xx.TableName FROM @table_inclusions xx) AND t.TABLE_NAME NOT IN ( SELECT xx.TableName FROM @table_exclusions xx)) 
		AND		
		( t.TABLE_SCHEMA IN( SELECT yy.SchemaName FROM @schema_inclusions yy ) AND t.TABLE_SCHEMA NOT IN( SELECT yy.SchemaName FROM @schema_exclusions yy ))
	ORDER BY t.TABLE_NAME;

	INSERT @powershell ( Line ) VALUES ( '"/d:false"' );
	INSERT @powershell ( Line ) VALUES ( '' );
	INSERT @powershell ( Line ) VALUES ( '& "C:\Program Files\Microsoft SQL Server\160\DAC\bin\SqlPackage.exe" @params' );

	SELECT
		p.Line
	FROM @powershell p
	ORDER BY RowID;
