module CONN
    ##export connect,  disconnect

    import Base
    import DBI
    import PostgreSQL
    import IniFile
    import DataFrames

    """
    CONNECTION FUNCTION
    """
    function connect(
        file_ini_name::String, connection_name::String="default"
    )
        ini = IniFile.Inifile()
        IniFile.read(ini, file_ini_name)
        """
        return Base.connect(
            PostgreSQL.Postgres, "localhost", "lab", "lab", "julia", 5432
        )
        """
        try
            return Base.connect(
                PostgreSQL.Postgres,
                IniFile.get(ini, connection_name, "hostname"),
                IniFile.get(ini, connection_name, "username"),
                IniFile.get(ini, connection_name, "password"),
                IniFile.get(ini, connection_name, "database"),
                IniFile.get(ini, connection_name, "port")
            )
        catch err
            return Nothing
        end
    end

    """
    EXECUTE

    Execute a sql statement with optional dictionary values

    @param conn: PostgreSQL.PostgresDatabaseHandle -> connection object
    @param sql: String -> sql string, can use format string structure
    @param values: Dict, optional, default={} -> dictionary to merge with sql
    @return: DataFrames.DataFrame -> DataFrame with all results
    """
    function execute(
        conn::PostgreSQL.PostgresDatabaseHandle,
        sql::String,
        values::Dict=Dict()
    )
        stmt = DBI.prepare(conn, sql)
        result = DBI.execute(stmt)
        finish(stmt)
        return DBI.fetchdf(result)
    end

    """
    RUN

    Run a sql statement with optional dictionary values

    @param conn: PostgreSQL.PostgresDatabaseHandle -> connection object
    @param sql: String -> sql string, can use format string structure
    @param values: Dict, optional, default={} -> dictionary to merge with sql

    """
    function run(
        conn::PostgreSQL.PostgresDatabaseHandle,
        sql::String,
        values::Dict=Dict()
    )
        DBI.run(conn, sql)
        #testdberror(conn, PostgreSQL.CONNECTION_OK)
        return
    end

    """

    """
    function finish(stmt::PostgreSQL.PostgresStatementHandle)
        return DBI.finish(stmt)
    end

    """

    """
    function disconnect(conn::PostgreSQL.PostgresDatabaseHandle)
        return DBI.disconnect(conn)
    end

end  # CONN
