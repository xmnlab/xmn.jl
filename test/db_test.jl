import DB

function test1()
    conn = DB.connect("/home/xmn/dev/julia/xmn.jl/test/conn.ini")

    """
    stmt = prepare(
        conn, "SELECT 1::bigint, 2.0::double precision, 'foo'::character varying, " *
                         "'foo'::character(10);")

    result = execute(stmt)
    """

    name = join(map(x->char(x), rand(65:90, rand(20:100))))

    sql = @sprintf(
        "INSERT INTO client1.client (id, name) VALUES (DEFAULT, '%s');", name
    )

    DB.run(conn, sql)

    result = DB.execute(
        conn, "select id::int, name::character varying from client1.client"
    )

    print(result)

    DB.disconnect(conn)
end


test1()
