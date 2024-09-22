import sqlalchemy
import numpy
import random
import datetime
from sqlalchemy.orm import Session
from datetime import timedelta


def getRandom(limite, limiteInf = None, umi = None, multiD = False): #funzione per avere l'1% delle registrazioni come alert
    gruppo1 = []
    gruppo2 = []
    limiteU = 0
    if(multiD):
        limiteU = - 2 * limite
    if(limiteInf != None):
        estremoInf = 0
        if(limiteInf > 0):
            estremoInf = 1/2 * limiteInf
        elif(limiteInf ==0):
            estremoInf = -limite
        else:
            estremoInf = 2 * limiteInf     
        gruppo = numpy.arange(estremoInf, 2*limite, limite/100)
        gruppo1 = [v for v in gruppo if (v <  limite and v > limiteInf)]
        gruppo2 = [v for v in gruppo if (v >= limite or v <= limiteInf)]
    elif umi != None:
        gruppo = numpy.arange(0, 100, limite/100)
        gruppo1 = [v for v in gruppo if v <  limite]
        gruppo2 = [v for v in gruppo if v >= limite]
    else:
        gruppo = numpy.arange(limiteU, 2*limite, limite/100)
        gruppo1 = [v for v in gruppo if v <  limite or v > limiteU]
        gruppo2 = [v for v in gruppo if v >= limite or v <= limiteU]
    arrayFinale = random.choice([gruppo1]*99 + [gruppo2]*1)
    return random.choice(arrayFinale)
    
db = sqlalchemy
engine = db.create_engine('mysql+pymysql://esame-database-unipi:P4$$word-esame-carlo@51.38.234.93:3306/esame_database_unipi')
conn = engine.connect()
metadata = db.MetaData()
tableName = input("Inserisci il nome della tabella: ")
table = db.Table(tableName, metadata, autoload=True, autoload_with=engine) #Registrazione
sensore1D = db.Table('Sensore1D', metadata, autoload=True, autoload_with=engine) #Sensore 1D
sensore2D = db.Table('Sensore2D', metadata, autoload=True, autoload_with=engine) #Sensore 2D
sensore3D = db.Table('Sensore3D', metadata, autoload=True, autoload_with=engine) #Sensore 3D
SogliaInferioreTb = db.Table('SogliaInferiore', metadata, autoload=True, autoload_with=engine)

session = Session(engine)
#session.execute('''TRUNCATE TABLE ''' + tableName + '''''')
#session.commit()


numeroSensori = int(input("Inserisci il numero di sensori coinvolti: "))

numeroRecord = int(input("Inserisci il numero di record da inserire per ogni sensore: "))


for sensore in range(numeroSensori):
    for i in range(numeroRecord):
        orario = (datetime.datetime.now() - numeroRecord * timedelta(minutes=15)) + i * timedelta(minutes=15) #ogni 15 minuti a partire dalla data da quando partono le registrazioni
        if tableName == "Registrazione1D":
            sens = session.query(sensore1D).filter(sensore1D.c.CodiceSensore == sensore).with_entities(sensore1D.c.Soglia, sensore1D.c.Tipo).first()[0]
            soglia, tipo = sens.Soglia, sens.Tipo
            umidita = None
            if tipo in ("UmiditaInterna", "UmiditaEsterna"):
                umidita = 1
            sogliaInf = session.query(SogliaInferioreTb).filter(SogliaInferioreTb.c.CodiceSensore == sensore).with_entities(SogliaInferioreTb.c.ValoreInf).first()
            if(sogliaInf != None):
                sogliaInf = sogliaInf[0]
            rec = table.insert().values(CodiceSensore=sensore, Timestamp = orario, Valore=getRandom(soglia, sogliaInf, umidita))
            result = conn.execute(rec)

        elif tableName == "Registrazione2D":
            sens = session.query(sensore2D).filter(sensore2D.c.CodiceSensore == sensore).with_entities(sensore2D.c.SogliaX, sensore2D.c.SogliaY).first()
            sogliaX, sogliaY = sens.SogliaX, sens.SogliaY
            rec = table.insert().values(CodiceSensore=sensore, Timestamp = orario, ValoreX=getRandom(sogliaX, multiD = True), ValoreY=getRandom(sogliaY, multiD = True))
            result = conn.execute(rec)

        elif tableName == "Registrazione3D":
            sens = session.query(sensore3D).filter(sensore3D.c.CodiceSensore == sensore).with_entities(sensore3D.c.SogliaX, sensore3D.c.SogliaY, sensore3D.c.SogliaZ).first()
            sogliaX, sogliaY, sogliaZ = sens.SogliaX, sens.SogliaY, sens.SogliaZ
            rec = table.insert().values(CodiceSensore=sensore, Timestamp = orario, ValoreX=getRandom(sogliaX, multiD = True), ValoreY=getRandom(sogliaY, multiD = True), ValoreZ=getRandom(sogliaZ, multiD = True))
            result = conn.execute(rec)
print("Inserimento completato")
