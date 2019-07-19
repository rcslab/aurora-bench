import sys

from mysql.connector import MySQLConnection

def pre():
    cnx = MySQLConnection(user='root', password='')
    cur = cnx.cursor(buffered=True)
    new_pass = (
            "ALTER USER 'root'@'localhost' IDENTIFIED BY 'db1234'"
            )

    # Required by sysbench
    create_d = (
            "CREATE DATABASE sbtest;"
            )
    cur.execute(new_pass)
    cur.execute(create_d)
    cur.close()
    cnx.close()

def startup():
    cnx = MySQLConnection(user='root', password='db1234')
    cur = cnx.cursor(buffered=True)
    create_d = (
            "CREATE DATABASE test;"
            )
    cur.execute(create_d)
    cur.close()
    cnx.close()

    cnx = MySQLConnection(user='root', password='db1234', database='test')

    startup = (
            "CREATE TABLE test"
            "(id INT, INDEX USING HASH (id))"
            "ENGINE=MEMORY;"
            )

    cur = cnx.cursor(buffered=True)

    fill = "INSERT INTO test\nVALUES"
    for x in range(1,1001):
        fill += "({}),".format(str(x))
    fill+= "(0);"
    cur.execute(startup)
    cur.execute(fill)
    cur.close()
    cnx.close()

def check():
    cnx = MySQLConnection(user='root', password='db1234', database='test')
    cur = cnx.cursor(buffered=True)

    c = (
        "SELECT * FROM test;"
        )
    cur.execute(c)
    vals = cur.fetchall()
    counter = 1
    error = False
    for x in vals:
        if x[0] != counter % 1001:
            print(x[0])
            print(counter)
            error = True
        counter += 1
    if counter != 1002:
        print(counter)
        error = True
    print(error)
    cur.close()
    cnx.close()
    

def cleanup():
    cnx = MySQLConnection(user='root', password='db1234', database='test')

    teardown = (
            "DROP DATABASE test"
            )

    cur = cnx.cursor(buffered=True)
    cur.execute(teardown)
    cur.close()
    cnx.close()

def main():
    if sys.argv[1] == 'start':
        startup()
    elif sys.argv[1] == 'clean':
        cleanup()
    elif sys.argv[1] == 'check':
        check()
    elif sys.argv[1] == 'pre':
        pre()
    else:
        print("ERROR")
        return 1
    

if __name__ == '__main__':
    main()




