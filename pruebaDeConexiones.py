import os
from sqlalchemy import create_engine, text

# --- Tus configuraciones ---
PG_ETHERIA_URL = os.getenv(
    "ETHERIA_PG_URL",
    "postgresql+psycopg2://admin:admin123@localhost:5432/ETHERIA GLOBAL",
)

MYSQL_DYNAMIC_URL = os.getenv(
    "DYNAMIC_MYSQL_URL",
    "mysql+pymysql://root:admin123@localhost:3306/dynamicBrandsDB",
)

PG_DW_URL = os.getenv(
    "DW_PG_URL",
    "postgresql+psycopg2://admin:admin123@localhost:5432/etheriaDW",
)

def test_connections():
    connections = {
        "PostgreSQL Etheria": PG_ETHERIA_URL,
        "MySQL Dynamic": MYSQL_DYNAMIC_URL,
        "PostgreSQL DW": PG_DW_URL
    }
    
    print("--- Verificando Conexiones ---")
    
    for name, url in connections.items():
        try:
            # Creamos el motor de conexión
            engine = create_engine(url)
            
            # Intentamos conectar y ejecutar un comando simple
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            
            print(f"✅ {name}: Conexión exitosa.")
            
        except Exception as e:
            print(f"❌ {name}: Error al conectar.")
            print(f"   Detalle: {e}\n")

if __name__ == "__main__":
    test_connections()