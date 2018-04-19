create or replace PACKAGE BODY  BLEX_WEBSERVICE AS

  PROCEDURE ND_TO_FS(P_ID IN NUMBER) IS
  
  FS_ID NUMBER;
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  counter NUMBER;
  strcurrval VARCHAR2(50);
  
  sla_end_dt DATE;
  
  BEGIN
  
      --goOn := 1;
  
      SELECT FS01_ACTIVITY_SEQ.NEXTVAL 
        INTO FS_ID
        FROM DUAL;
        
      -- inserisco la propriet della ODL nella tabella FS03_PROPERTY
      UTL_TABLE.TABLE_TO_FS_PROPERTY('ND01_ODI', 'ND01_ID_WFA', p_id, FS_ID,'NETDIS');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('ND03_CONTATORI', 'ND03_ID_WFA', p_id, FS_ID,'NETDIS');
      
      --se c'è un correttore eseguo anche su table ND04_CORRETTORI
      SELECT COUNT(ND04_ID_WFA) INTO counter FROM ND04_CORRETTORI WHERE ND04_ID_WFA = p_id;
      IF counter > 0 THEN
        UTL_TABLE.TABLE_TO_FS_PROPERTY('ND04_CORRETTORI', 'ND04_ID_WFA', p_id, FS_ID,'NETDIS');
      END IF;
      
      counter := 0;
      --nel caso di attività di posa cartelli (CAR / CAL) devono mandare un'attività come non programmata
      SELECT COUNT(ND01_COD_TIPO_INTERVENTO) into counter FROM ND01_ODI WHERE ND01_ID_WFA = p_id;
      IF counter > 0 THEN
        SELECT ND01_COD_TIPO_INTERVENTO into strcurrval FROM ND01_ODI WHERE ND01_ID_WFA = p_id;
        IF strcurrval = 'CAR' OR strcurrval = 'CAL' THEN
          --svuoto la data per inviare non programmata, setto lo sla end alla data di esecuzione
          SELECT FS01_DATE INTO sla_end_dt FROM FS01_ACTIVITY WHERE FS01_ID = FS_ID;
          UPDATE FS01_ACTIVITY SET FS01_DATE = null,FS01_TIME_SLOT = null, FS01_SLA_WINDOW_END = sla_end_dt WHERE FS01_ID = FS_ID;
          DELETE FROM FS03_PROPERTY WHERE FS03_ID_ACTIVITY = FS_ID AND (FS03_LABEL = 'xa_end_ts_nout' OR FS03_LABEL = 'xa_start_ts_nout');
        END IF;
      END IF;
        
      --se tutto ok rispondo altrimenti vado in exception
      SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0'),
                XMLELEMENT("ID", FS_ID)
              )
          INTO xml
          FROM dual; 
  
      UTIL_HTP.HTP_XML (xml);
      
      EXCEPTION WHEN others THEN
      
      err_code := SQLCODE;
      err_msg := substr(SQLERRM, 1, 4000);
             
      SELECT XMLELEMENT("RESPONSE",
                  XMLELEMENT("STATUS", err_code),
                  XMLELEMENT("ERROR", err_msg)
                )
             INTO xml
             FROM dual;            
          
      UTIL_HTP.HTP_XML (xml); 

      DBMS_OUTPUT.PUT_LINE('--ERRORE - MSG:'|| err_msg); 
      
      --HTP.P(SQLERRM);
  END;

  PROCEDURE FS_TO_ND(P_ID IN NUMBER) IS
  
  ID_WFA NUMBER;
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  
  BEGIN
  
     SELECT SEQ_ID_WFA.NEXTVAL 
        INTO ID_WFA
        FROM DUAL;
  
      
      -- uso le property to table per tutte le tabelle di neta
      UTL_TABLE.FS_PROPERTY_TO_TABLE('ND13_OUT_ODI','ND13_OUT_ID_WFA',p_id,p_id);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('ND25_OUT_RSGM','ND25_OUT_ID_WFA',p_id,p_id);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('ND14_OUT_CONTATORI_ESISTENTI','ND14_OUT_ID_WFA',p_id,p_id);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('ND15_OUT_CONTATORI_INSTALLATI','ND15_OUT_ID_WFA',p_id,p_id);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('ND14B_OUT_CORRETTORI_ESISTENTI','ND14B_OUT_ID_WFA',p_id,p_id);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('ND15B_OUT_CORR_INSTALLATI','ND15B_OUT_ID_WFA',p_id,p_id);

            
      SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0'),
                XMLELEMENT("ID", ID_WFA)
              )
          INTO xml
          FROM dual; 
  
      UTIL_HTP.HTP_XML (xml);
      
      EXCEPTION WHEN others THEN
      
      err_code := SQLCODE;
      err_msg := substr(SQLERRM, 1, 4000);
             
      SELECT XMLELEMENT("RESPONSE",
                  XMLELEMENT("STATUS", err_code),
                  XMLELEMENT("ERROR", err_msg)
                )
             INTO xml
             FROM dual;            
          
      UTIL_HTP.HTP_XML (xml); 
      
  END;

  PROCEDURE FS_TO_ND(P_ID IN NUMBER, exitValue OUT VARCHAR2) IS
  
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  
  BEGIN
        
      -- uso le property to table per tutte le tabelle di neta
      UTL_TABLE.FS_PROPERTY_TO_TABLE('ND13_OUT_ODI','ND13_OUT_ID_WFA',p_id,p_id);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('ND25_OUT_RSGM','ND25_OUT_ID_WFA',p_id,p_id);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('ND14_OUT_CONTATORI_ESISTENTI','ND14_OUT_ID_WFA',p_id,p_id);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('ND15_OUT_CONTATORI_INSTALLATI','ND15_OUT_ID_WFA',p_id,p_id);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('ND14B_OUT_CORRETTORI_ESISTENTI','ND14B_OUT_ID_WFA',p_id,p_id);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('ND15B_OUT_CORR_INSTALLATI','ND15B_OUT_ID_WFA',p_id,p_id);

      exitValue := '';
      
      EXCEPTION WHEN others THEN
      
      err_code := SQLCODE;
      err_msg := substr(SQLERRM, 1, 4000);    
          
      exitValue := (err_code || err_msg);
      
  END;

  PROCEDURE TRN_TO_FS(P_ID IN NUMBER) IS
  
  FS_ID NUMBER;
  xml   XMLTYPE;
  service   VARCHAR2(20);
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  
  BEGIN  
      SELECT FS01_ACTIVITY_SEQ.NEXTVAL 
        INTO FS_ID
        FROM DUAL;

      -- inserisco la propriet della ODL nella tabella FS03_PROPERTY(si occupa di inserire anche i valori nella fs01)
      SELECT tn.TN03_KS INTO service FROM TN03_WFM_ANDATA tn WHERE tn.TN03_ID_WFA = p_id;
      
      IF service = 'G' THEN
        UTL_TABLE.TABLE_TO_FS_PROPERTY('TN03_WFM_ANDATA', 'TN03_ID_WFA', p_id, FS_ID,'RETI4','Gas');
      ELSE
        UTL_TABLE.TABLE_TO_FS_PROPERTY('TN03_WFM_ANDATA', 'TN03_ID_WFA', p_id, FS_ID,'RETI4','Idrico');

        -- update del bucket
        BLEX_WEBSERVICE.SET_BUCKET(FS_ID);
      END IF;

      -- trasformo le coordinate in sistema oracle
      GEO_WEBSERVICE.COORD_TRN_to_FS (p_id, FS_ID);
                  
      SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0'),
                XMLELEMENT("ID", FS_ID)
              )
          INTO xml
          FROM dual; 
  
      UTIL_HTP.HTP_XML (xml);
      
      EXCEPTION WHEN others THEN
      
      err_code := SQLCODE;
      err_msg := substr(SQLERRM, 1, 4000);
             
      SELECT XMLELEMENT("RESPONSE",
                  XMLELEMENT("STATUS", err_code),
                  XMLELEMENT("ERROR", err_msg)
                )
             INTO xml
             FROM dual;            
          
      UTIL_HTP.HTP_XML (xml); 
      
      --HTP.P(SQLERRM);
  END;

  PROCEDURE FS_TO_TRN(P_ID IN NUMBER) IS
  
  ID_WFA NUMBER;
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  
  BEGIN
  
  
     SELECT SEQ_ID_WFA.NEXTVAL 
        INTO ID_WFA
        FROM DUAL;
  
      
      -- uso le property to table per tutte le tabelle di neta
      UTL_TABLE.FS_PROPERTY_TO_TABLE('TN05_WFM_RITORNO','TN05_ID_WFA',p_id,ID_WFA);

            
      SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0'),
                XMLELEMENT("ID", ID_WFA)
              )
          INTO xml
          FROM dual; 
  
      UTIL_HTP.HTP_XML (xml);
      
      EXCEPTION WHEN others THEN
      
      err_code := SQLCODE;
      err_msg := substr(SQLERRM, 1, 4000);
             
      SELECT XMLELEMENT("RESPONSE",
                  XMLELEMENT("STATUS", err_code),
                  XMLELEMENT("ERROR", err_msg)
                )
             INTO xml
             FROM dual;            
          
      UTIL_HTP.HTP_XML (xml); 
      
  END;

  PROCEDURE SAP_TO_FS(P_ID IN NUMBER) IS
  
  FS_ID NUMBER;
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  
  BEGIN
      
      --goOn := 1;
  
      SELECT FS01_ACTIVITY_SEQ.NEXTVAL 
        INTO FS_ID
        FROM DUAL;
      
      -- inserisco la propriet della ODMADM nella tabella FS03_PROPERTY
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM01_ODM_TESTATA_ORDINE', 'PM01_ID', p_id, FS_ID,'SAP');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM02_ODM_INDIRIZZO', 'PM02_ID', p_id, FS_ID,'SAP');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM03_ODM_OGGETTO_TECNICO', 'PM03_ID', p_id, FS_ID,'SAP');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM04_ODM_OPERAZIONE_ORDINE', 'PM04_ID', p_id, FS_ID,'SAP');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM05_ODM_CUST_OP_ORD', 'PM05_ID', p_id, FS_ID,'SAP');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM06_ODM_TESTATA_AVVISO', 'PM06_ID', p_id, FS_ID,'SAP');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM07_ODM_CUST_TEST_ORD', 'PM07_ID', p_id, FS_ID,'SAP');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM08_ODM_REL_OPE_ORD', 'PM08_ID', p_id, FS_ID,'SAP');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM09_ODM_OP_ORD_TXT_EST', 'PM09_ID', p_id, FS_ID,'SAP');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM10_ODM_MAT_OP_ORD', 'PM10_ID', p_id, FS_ID,'SAP');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM11_ODM_SEG_CAR_CLA_SEDE_TEC', 'PM11_ID', p_id, FS_ID,'SAP');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM42_ODM_CLASSE_SEDE_TECNICA', 'PM42_ID', p_id, FS_ID,'SAP');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM45_CHK_JSON', 'PM45_ID', p_id, FS_ID,'SAP');
      
      SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0'),
                XMLELEMENT("ID", FS_ID)
              )
          INTO xml
          FROM dual; 
  
      UTIL_HTP.HTP_XML (xml);
      
      EXCEPTION WHEN others THEN
      
      err_code := SQLCODE;
      err_msg := substr(SQLERRM, 1, 4000);
             
      SELECT XMLELEMENT("RESPONSE",
                  XMLELEMENT("STATUS", err_code),
                  XMLELEMENT("ERROR", err_msg)
                )
             INTO xml
             FROM dual;            
          
      UTIL_HTP.HTP_XML (xml); 
      
      --HTP.P(SQLERRM);
  END;
  
  PROCEDURE FS_TO_SAP(P_ID IN NUMBER) IS
  
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  
  BEGIN
  
      UTL_TABLE.FS_PROPERTY_TO_TABLE('PM43_AEM_OUT','PM43_ID_WFA',P_ID,P_ID);

  END;

  PROCEDURE SAP_ADM_TO_FS(P_ID IN NUMBER) IS
  
  FS_ID NUMBER;
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  
  BEGIN
  
     SELECT FS01_ACTIVITY_SEQ.NEXTVAL 
        INTO FS_ID
        FROM DUAL;
  
      
      -- uso le property to table per tutte le tabelle di neta
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM12_ADM_TEST_AVV_MANU','PM12_ID',p_id,FS_ID,'SAP-PM-A');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM15_ADM_INDIRIZZO','PM15_ID',p_id,FS_ID,'SAP-PM-A');
      UTL_TABLE.TABLE_TO_FS_PROPERTY('PM16_ADM_SEGMENTO_SCADENZE','PM16_ID',p_id,FS_ID,'SAP-PM-A');

            
      SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0'),
                XMLELEMENT("ID", FS_ID)
              )
          INTO xml
          FROM dual; 
  
      UTIL_HTP.HTP_XML (xml);
      
      EXCEPTION WHEN others THEN
      
      err_code := SQLCODE;
      err_msg := substr(SQLERRM, 1, 4000);
             
      SELECT XMLELEMENT("RESPONSE",
                  XMLELEMENT("STATUS", err_code),
                  XMLELEMENT("ERROR", err_msg)
                )
             INTO xml
             FROM dual;            
          
      UTIL_HTP.HTP_XML (xml); 

  END SAP_ADM_TO_FS;

  PROCEDURE SAP_MULTI_TO_FS(P_ID IN NUMBER) IS

  FS_ID NUMBER;
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  L_PRODOTTO UT15_TIPI_ATTIVITA_SAP.UT15_PRODOTTO%TYPE;
  L_SERVIZIO UT15_TIPI_ATTIVITA_SAP.UT15_SERVIZIO%TYPE;
  L_TIPO_ATTIVITA PM04_ODM_OPERAZIONE_ORDINE.PM04_KTSCH%TYPE;
  MESSAGE_COUNT number;
  LAST_STATUS VARCHAR2(50);
  CURSOR TAB IS
  SELECT PM04.*
  FROM   PM04_ODM_OPERAZIONE_ORDINE PM04
  WHERE  PM04.PM04_ID = P_ID;

  BEGIN

  SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0')
              )
          INTO xml
          FROM dual; 

  FOR T IN TAB LOOP

    SELECT FS01_ACTIVITY_SEQ.NEXTVAL 
      INTO FS_ID
      FROM DUAL;

    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM01_ODM_TESTATA_ORDINE', 'PM01_ID', p_id, FS_ID,'SAP-PM-O','Multiple_Operaz');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM02_ODM_INDIRIZZO', 'PM02_ID', p_id, FS_ID,'SAP-PM-O','Multiple_Operaz');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM03_ODM_OGGETTO_TECNICO', 'PM03_ID', p_id, FS_ID,'SAP-PM-O','Multiple_Operaz');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM04_ODM_OPERAZIONE_ORDINE', 'PM04_INTERNAL_ID', t.PM04_INTERNAL_ID, FS_ID,'SAP-PM-O','Multiple_Operaz');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM05_ODM_CUST_OP_ORD', 'PM05_ID', p_id, FS_ID,'SAP-PM-O','Multiple_Operaz');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM06_ODM_TESTATA_AVVISO', 'PM06_ID', p_id, FS_ID,'SAP-PM-O','Multiple_Operaz');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM07_ODM_CUST_TEST_ORD', 'PM07_ID', p_id, FS_ID,'SAP-PM-O','Multiple_Operaz');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM08_ODM_REL_OPE_ORD', 'PM08_ID', p_id, FS_ID,'SAP-PM-O','Multiple_Operaz');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM09_ODM_OP_ORD_TXT_EST', 'PM09_ID', p_id, FS_ID,'SAP-PM-O','Multiple_Operaz');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM10_ODM_MAT_OP_ORD', 'PM10_ID', p_id, FS_ID,'SAP-PM-O','Multiple_Operaz');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM11_ODM_SEG_CAR_CLA_SEDE_TEC', 'PM11_ID', p_id, FS_ID,'SAP-PM-O','Multiple_Operaz');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM42_ODM_CLASSE_SEDE_TECNICA', 'PM42_ID', p_id, FS_ID,'SAP-PM-O','Multiple_Operaz');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM45_CHK_JSON', 'PM45_ID', p_id, FS_ID,'SAP-PM-O','Multiple_Operaz');

    -- ###########    gestione idrico   ##############
    --recupero tipo attivita
    select PM04_KTSCH
    into L_TIPO_ATTIVITA
    from PM04_ODM_OPERAZIONE_ORDINE
    where PM04_INTERNAL_ID =  t.PM04_INTERNAL_ID;
    --recupero linea prodotto
    select UT15_PRODOTTO, UT15_SERVIZIO
    into L_PRODOTTO, L_SERVIZIO
    from UT15_TIPI_ATTIVITA_SAP
    where UT15_TIPO_SAP = L_TIPO_ATTIVITA;

    if L_PRODOTTO = 'ACQUA' then
      -- update del bucket
      BLEX_WEBSERVICE.SET_BUCKET(FS_ID);
      --update linea prodotto
      update FS03_PROPERTY set FS03_VALUE = DECODE (L_SERVIZIO, 'DEPURAZIONE', 'D', 
                             'POTABILI', 'A', 
                             'FOGNATURE', 'R',
                                'A') 
      where FS03_ID_ACTIVITY = FS_ID and FS03_LABEL = 'xa_evt_linea_prodotto';
      --update tipo servizio
      update FS03_PROPERTY set FS03_VALUE = DECODE  (L_SERVIZIO, 'DEPURAZIONE', 'DEP', 
                             'POTABILI', 'H2O', 
                             'FOGNATURE', 'REFLUE',
                                'H2O') 
      where FS03_ID_ACTIVITY = FS_ID and FS03_LABEL = 'xa_tipo_servizio';
    end if;
    -- ###########  fine gestione idrico   ##############

    --tk 2018020910000339 impedire reinvio di attivita gia started o completed. cerco su fs07 se ho ricevuto per attivita con stesso appt number i messaggi di complete o start
    select count(co.MESSAGE_ID)
    into MESSAGE_COUNT
    from FS07_COMPLETE co
    join FS09_COMPLETE_PROPERTY pr on co.MESSAGE_ID = pr.MESSAGE_ID 
    and pr.FS09_LABEL = 'xa_sistema_origine'
    join FS01_ACTIVITY ac on ac.FS01_APPT_NUMBER = co.FS07_APPTNUMBER
    where co.FS07_ACTIVITYSTATUS in ('started','complete') and ac.FS01_ID = FS_ID
    and dbms_lob.compare(pr.FS09_VALUE, 'SAP-PM-O') = 0;

    if MESSAGE_COUNT = 0 then
      select INSERTCHILDXML(
        xml,'RESPONSE','ID', XMLELEMENT("ID", FS_ID) 
      )
      into xml
      from dual;
    else      
      select FS07_ACTIVITYSTATUS
      into LAST_STATUS
      from (select co.FS07_ACTIVITYSTATUS from FS07_COMPLETE co
      join FS09_COMPLETE_PROPERTY pr on co.MESSAGE_ID = pr.MESSAGE_ID 
      and pr.FS09_LABEL = 'xa_sistema_origine'
      join FS01_ACTIVITY ac on ac.FS01_APPT_NUMBER = co.FS07_APPTNUMBER
      where ac.FS01_ID = FS_ID
      and dbms_lob.compare(pr.FS09_VALUE, 'SAP-PM-O') = 0
      ORDER BY RECEIVED Desc) where  ROWNUM = 1;

      if LAST_STATUS = 'suspended' or LAST_STATUS = 'cancelled' then
        select INSERTCHILDXML(
          xml,'RESPONSE','ID', XMLELEMENT("ID", FS_ID) 
        )
        into xml
        from dual;
      end if;
    end if;
    

  END LOOP;
    
  
  
      UTIL_HTP.HTP_XML (xml);
      
  EXCEPTION WHEN others THEN
  
    err_code := SQLCODE;
    err_msg := substr(SQLERRM, 1, 4000);
            
    SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", err_code),
                XMLELEMENT("ERROR", err_msg)
              )
            INTO xml
            FROM dual;            
        
    UTIL_HTP.HTP_XML (xml); 

  END;

  PROCEDURE SAP_MULTIAV_TO_FS(P_ID IN NUMBER) IS

  FS_ID NUMBER;
  xml   XMLTYPE;
  goOn NUMBER;
  MESSAGE_COUNT number;
  LAST_STATUS VARCHAR2(50);
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  v_query_str VARCHAR2(1000);
  L_PRODOTTO UT15_TIPI_ATTIVITA_SAP.UT15_PRODOTTO%TYPE;
  L_SERVIZIO UT15_TIPI_ATTIVITA_SAP.UT15_SERVIZIO%TYPE;
  L_TIPO_ATTIVITA PM04_ODM_OPERAZIONE_ORDINE.PM04_KTSCH%TYPE;
  CURSOR TAB IS
  SELECT PM06.*
  FROM   PM06_ODM_TESTATA_AVVISO PM06
  WHERE  PM06.PM06_ID = P_ID;

  BEGIN

  SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0')
              )
          INTO xml
          FROM dual; 

  FOR T IN TAB LOOP

    SELECT FS01_ACTIVITY_SEQ.NEXTVAL 
      INTO FS_ID
      FROM DUAL;

    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM01_ODM_TESTATA_ORDINE', 'PM01_ID', p_id, FS_ID,'SAP-PM-A','Multiple_Avvisi');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM02_ODM_INDIRIZZO', 'PM02_ID', p_id, FS_ID,'SAP-PM-A','Multiple_Avvisi');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM03_ODM_OGGETTO_TECNICO', 'PM03_ID', p_id, FS_ID,'SAP-PM-A','Multiple_Avvisi');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM04_ODM_OPERAZIONE_ORDINE', 'PM04_ID', p_id, FS_ID,'SAP-PM-A','Multiple_Avvisi');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM05_ODM_CUST_OP_ORD', 'PM05_ID', p_id, FS_ID,'SAP-PM-A','Multiple_Avvisi');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM06_ODM_TESTATA_AVVISO', 'PM06_INTERNAL_ID', t.PM06_INTERNAL_ID, FS_ID,'SAP-PM-A','Multiple_Avvisi');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM07_ODM_CUST_TEST_ORD', 'PM07_ID', p_id, FS_ID,'SAP-PM-A','Multiple_Avvisi');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM08_ODM_REL_OPE_ORD', 'PM08_ID', p_id, FS_ID,'SAP-PM-A','Multiple_Avvisi');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM09_ODM_OP_ORD_TXT_EST', 'PM09_ID', p_id, FS_ID,'SAP-PM-A','Multiple_Avvisi');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM10_ODM_MAT_OP_ORD', 'PM10_ID', p_id, FS_ID,'SAP-PM-A','Multiple_Avvisi');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM11_ODM_SEG_CAR_CLA_SEDE_TEC', 'PM11_ID', p_id, FS_ID,'SAP-PM-A','Multiple_Avvisi');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM42_ODM_CLASSE_SEDE_TECNICA', 'PM42_ID', p_id, FS_ID,'SAP-PM-A','Multiple_Avvisi');
    UTL_TABLE.TABLE_TO_FS_PROPERTY('PM45_CHK_JSON', 'PM45_ID', p_id, FS_ID,'SAP-PM-A','Multiple_Avvisi');

    --update appt_number in base a pm06
    --v_query_str := 'update FS01_ACTIVITY set FS01_APPT_NUMBER = '||t.PM06_AUFNR||'-'||t.PM06_QMNUM||'-'||t.PM06_VORNR||' where FS01_ID = ' || FS_ID;
    --DBMS_OUTPUT.PUT_LINE(v_query_str); 
    --EXECUTE IMMEDIATE v_query_str;

    -- ###########    gestione idrico   ##############
    --recupero tipo attivita
    select PM04_KTSCH
    into L_TIPO_ATTIVITA
    from PM04_ODM_OPERAZIONE_ORDINE
    where PM04_ID =  p_id
    and ROWNUM = 1;
    --recupero linea prodotto
    select UT15_PRODOTTO, UT15_SERVIZIO
    into L_PRODOTTO, L_SERVIZIO
    from UT15_TIPI_ATTIVITA_SAP
    where UT15_TIPO_SAP = L_TIPO_ATTIVITA;

    if L_PRODOTTO = 'ACQUA' then
      -- update del bucket
      BLEX_WEBSERVICE.SET_BUCKET(FS_ID);
       --update linea prodotto
      update FS03_PROPERTY set FS03_VALUE = DECODE (L_SERVIZIO, 'DEPURAZIONE', 'D', 
                             'POTABILI', 'A', 
                             'FOGNATURE', 'R',
                                'A') 
      where FS03_ID_ACTIVITY = FS_ID and FS03_LABEL = 'xa_evt_linea_prodotto';
      --update tipo servizio
      update FS03_PROPERTY set FS03_VALUE = DECODE  (L_SERVIZIO, 'DEPURAZIONE', 'DEP', 
                             'POTABILI', 'H2O', 
                             'FOGNATURE', 'REFLUE',
                                'H2O') 
      where FS03_ID_ACTIVITY = FS_ID and FS03_LABEL = 'xa_tipo_servizio';
    end if;
    -- ###########  fine gestione idrico   ##############

    --tk 2018020910000339 impedire reinvio di attivita gia started o completed. cerco su fs07 se ho ricevuto per attivita con stesso appt number i messaggi di complete o start
    select count(co.MESSAGE_ID)
    into MESSAGE_COUNT
    from FS07_COMPLETE co
    join FS09_COMPLETE_PROPERTY pr on co.MESSAGE_ID = pr.MESSAGE_ID 
    and pr.FS09_LABEL = 'xa_sistema_origine'
    join FS01_ACTIVITY ac on ac.FS01_APPT_NUMBER = co.FS07_APPTNUMBER
    where co.FS07_ACTIVITYSTATUS in ('started','complete') and ac.FS01_ID = FS_ID
    and dbms_lob.compare(pr.FS09_VALUE, 'SAP-PM-A') = 0;

    if MESSAGE_COUNT = 0 then
      select INSERTCHILDXML(
        xml,'RESPONSE','ID', XMLELEMENT("ID", FS_ID) 
      )
      into xml
      from dual;
    else      
      select FS07_ACTIVITYSTATUS
      into LAST_STATUS
      from (select co.FS07_ACTIVITYSTATUS from FS07_COMPLETE co
      join FS09_COMPLETE_PROPERTY pr on co.MESSAGE_ID = pr.MESSAGE_ID 
      and pr.FS09_LABEL = 'xa_sistema_origine'
      join FS01_ACTIVITY ac on ac.FS01_APPT_NUMBER = co.FS07_APPTNUMBER
      where ac.FS01_ID = FS_ID
      and dbms_lob.compare(pr.FS09_VALUE, 'SAP-PM-A') = 0
      ORDER BY RECEIVED Desc) where  ROWNUM = 1;

      if LAST_STATUS = 'suspended' or LAST_STATUS = 'cancelled' then
        select INSERTCHILDXML(
          xml,'RESPONSE','ID', XMLELEMENT("ID", FS_ID) 
        )
        into xml
        from dual;
      end if;
    end if;
    

  END LOOP;
    
  
  
      UTIL_HTP.HTP_XML (xml);
      
  EXCEPTION WHEN others THEN
  
    err_code := SQLCODE;
    err_msg := substr(SQLERRM, 1, 4000);
            
    SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", err_code),
                XMLELEMENT("ERROR", err_msg)
              )
            INTO xml
            FROM dual;            
        
    UTIL_HTP.HTP_XML (xml); 

  END;

  PROCEDURE MULTI_FS_TO_TRN(P_XML VARCHAR2) IS
  
  ID_WFA NUMBER;
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  service_type VARCHAR2(1);

  mex XMLTYPE;
  v_temp XMLTYPE;
  idMessage VARCHAR2(50);
  countMex INTEGER;

  CURSOR cxml IS
  SELECT VALUE (xml_tag) xmlMex
  FROM TABLE (XMLSEQUENCE (EXTRACT (XMLTYPE(p_xml), '/Messages/ID'))) xml_tag;
  
  BEGIN
    
    SELECT 
      XMLELEMENT("RESPONSE", '')
    INTO xml
    FROM dual;

    FOR c IN cxml
    LOOP
      BEGIN

        SELECT EXTRACTVALUE (c.xmlMex, '/ID') 
        INTO idMessage
        FROM dual;

        SELECT SEQ_ID_WFA.NEXTVAL 
        INTO ID_WFA
        FROM DUAL;

        service_type := FS_WEBSERVICE.GET_PROPERTY_VALUE(idMessage, 'xa_evt_linea_prodotto');
        v_temp := xml;

        --in base al service type instrado l'esecuzione
        CASE WHEN service_type = 'G' THEN
          -- Caso GAS
          UTL_TABLE.FS_PROPERTY_TO_TABLE_TRN('TN05_WFM_RITORNO','TN05_ID_WFA',idMessage,ID_WFA,'Gas');
        
          TN_WEBSERVICE.TRN_RETURN_MORE('TN05_WFM_RITORNO','TN05_ID_WFA',idMessage,ID_WFA,'Gas');
        
          -- setto le eventuali coordinate
          GEO_WEBSERVICE.COORD_FS_to_TRN(idMessage,ID_WFA);

          SELECT INSERTCHILDXML(
            v_temp, '/RESPONSE', 'TRNResponse', XMLType('<TRNResponse><ID_WFA>'|| ID_WFA ||'</ID_WFA><STATUS>0</STATUS></TRNResponse>') )
            into xml
          from dual;

        WHEN service_type = 'A' THEN
          -- Caso IDRICO
          UTL_TABLE.FS_PROPERTY_TO_TABLE_TRN('TN05_WFM_RITORNO','TN05_ID_WFA',idMessage,ID_WFA,'Idrico');
        
          TN_WEBSERVICE.TRN_RETURN_MORE('TN05_WFM_RITORNO','TN05_ID_WFA',idMessage,ID_WFA,'Idrico');
        
          -- setto le eventuali coordinate
          GEO_WEBSERVICE.COORD_FS_to_TRN(idMessage,ID_WFA);

          SELECT INSERTCHILDXML(
            v_temp, '/RESPONSE', 'TRNResponse', XMLType('<TRNResponse><ID_WFA>'|| ID_WFA ||'</ID_WFA><STATUS>0</STATUS></TRNResponse>') )
            into xml
          from dual;

        WHEN service_type is null THEN
          -- in caso di service type null rispondo con l'errore: Service Type non trovato
          SELECT INSERTCHILDXML(
            v_temp, '/RESPONSE', 'TRNResponse', XMLType('<TRNResponse><ID_WFA>'|| ID_WFA ||'</ID_WFA><STATUS>1</STATUS><ERROR>Errore: Linea Prodotto non trovata</ERROR></TRNResponse>') )
            into xml
          from dual;
          TN_WEBSERVICE.LOG_ERROR(idMessage,'Linea Prodotto non trovata',xml.getClobVal(),'Consuntivazione','BLEX');

        ELSE
          -- in caso di service type null rispondo con l'errore: Service Type non trovato
          SELECT INSERTCHILDXML(
            v_temp, '/RESPONSE', 'TRNResponse', XMLType('<TRNResponse><ID_WFA>'|| ID_WFA ||'</ID_WFA><STATUS>1</STATUS><ERROR>Errore: Linea Prodotto sconosciuta</ERROR></TRNResponse>') )
            into xml
          from dual;
          TN_WEBSERVICE.LOG_ERROR(idMessage,'Linea Prodotto sconosciuta',xml.getClobVal(),'Consuntivazione','BLEX');

        END CASE;

      EXCEPTION WHEN others THEN
        err_code := SQLCODE;
        err_msg := substr(SQLERRM, 1, 4000);  
        v_temp := xml;
        SELECT INSERTCHILDXML(
          v_temp, '/RESPONSE', 'TRNResponse', XMLType('<TRNResponse><ID_WFA>'|| ID_WFA ||'</ID_WFA><STATUS>1</STATUS><ERROR>'||err_msg||'</ERROR></TRNResponse>') )
        into xml
        from dual;
        
        TN_WEBSERVICE.LOG_ERROR(idMessage,to_clob(err_msg),xml.getClobVal(),'Consuntivazione','BLEX');

      END;   
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Finito'); 
  
    UTIL_HTP.HTP_XML (xml);
  

  EXCEPTION WHEN others THEN

    err_code := SQLCODE;
    err_msg := substr(SQLERRM, 1, 4000);  
    
    SELECT 
      XMLELEMENT("RESPONSE",
        XMLELEMENT("STATUS", '1'),
        XMLELEMENT("ERROR", err_msg))
    INTO xml
    FROM dual;
    
    DBMS_OUTPUT.PUT_LINE(err_msg); 
    
    UTIL_HTP.HTP_XML (xml);
      
  END MULTI_FS_TO_TRN;

  PROCEDURE CREATE_JSON_CHECKLIST(P_ID IN NUMBER) IS
    xml   XMLTYPE;
    err_code  VARCHAR2(50);
    err_msg   VARCHAR2(4000);
    vJson CLOB;
    vSezione varchar2(100);
    vCount NUMBER;
    vConformita varchar2(100);
    vStrMis varchar2(10);
    vVal varchar2(10);
    vDescrPoint varchar2(100);
    vTipoAttivita varchar2(20);
    vInternalId number;
    CURSOR TAB IS
    select * from PM04_ODM_OPERAZIONE_ORDINE 
    where PM04_ID = P_ID;

  BEGIN
  
    
    --ciclo su tutte le operazioni
    FOR PM04 IN TAB LOOP
        --tengo da parte i campi dell'operazione
        vInternalId := PM04.PM04_INTERNAL_ID;
        vTipoAttivita := PM04.PM04_KTSCH;
        vCount := 0;

        --creo intestazione json
        vJson := '{"rowTemplate": ["label","label","label","label","label","min","max","label","valore","select","textarea","testo","resource","date"],"colHeaders":["PdM","SAP Id","Desc Equip","SN","Costruttore","Lim. inf.","Lim. Sup.","Val. Rifer.","Valore","Conformità","Note","Str. di Mis.","Esecutore","Data esecuzione"],"DATA":{' ;
        vSezione := '';
        FOR T IN (SELECT PM44.*
                    FROM   PM44_CHK_OGGETTO_TECNICO PM44
                    WHERE  PM44.PM44_ID = P_ID AND PM44.PM44_DSTXT like '%' || vTipoAttivita || '%' ORDER BY PM44.PM44_PSORT, PM44.PM44_SEZIONE)  LOOP
          DBMS_OUTPUT.PUT_LINE('vSezione: '||vSezione||' PM44Sez: '||T.PM44_SEZIONE); 
          if T.PM44_SEZIONE <> vSezione or vSezione is null THEN
            --nuova sezione, se non è la prima chiudo la precedente
            if vSezione is not null then
              dbms_lob.append(vJson, '],');
            end if;
            vSezione := T.PM44_SEZIONE;
            dbms_lob.append(vJson, '"'||vSezione||'":[');
          else
            dbms_lob.append(vJson, ',');
          end if;

          --verifico se conformita = picklist
          vConformita := T.PM44_ATNAM;
          if vConformita = 'C_NC_NA' then
            --picklist
            vVal := '-';
            vStrMis := '-';
            vDescrPoint := T.PM44_PTTXT;
          else
            --unita di misura
            --picklist
            vVal := '';
            vStrMis := '';
            vDescrPoint := T.PM44_PTTXT || ' ' || T.PM44_UNITC;
          end if;

          --append del record di checklist
          dbms_lob.append(vJson, '["'||vDescrPoint||'","'||T.PM44_POINT||'","'||T.PM44_DESC_EQUIP||'","'||T.PM44_NUM_SERIE||'","'||T.PM44_COSTRUTTORE||'","'||T.PM44_LIM_INF||'","'||T.PM44_LIM_SUP||'","'||T.PM44_VAL_RIF||'","'||vVal||'","'||vConformita||'","","'||vStrMis||'","",""]');  
          vCount := vCount + 1;
        END LOOP;
        if vSezione is not null then
          dbms_lob.append(vJson, ']');
        end if;

        dbms_lob.append(vJson, '}}');

        --se non ho elementi json = null
        if vCount = 0 then
          vJson := null;
        end if;
        --inserimento su PM45  OLD. Ora associo chk filtrata per operazione a pm04  
        --INSERT INTO PM45_CHK_JSON (PM45_ID,PM45_JSON) VALUES (P_ID,vJson);
        UPDATE PM04_ODM_OPERAZIONE_ORDINE SET PM04_CHECKLIST = vJson WHERE PM04_ID = P_ID AND PM04_INTERNAL_ID = vInternalId;

    END LOOP;

    


    SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0')
              )
          INTO xml
          FROM dual; 
      
    UTIL_HTP.HTP_XML (xml);
        
  EXCEPTION WHEN others THEN
    
      err_code := SQLCODE;
      err_msg := substr(SQLERRM, 1, 4000);
            
      SELECT XMLELEMENT("RESPONSE",
                  XMLELEMENT("STATUS", err_code),
                  XMLELEMENT("ERROR", err_msg)
                )
              INTO xml
              FROM dual;            
        
      UTIL_HTP.HTP_XML (xml); 

  END CREATE_JSON_CHECKLIST;



  PROCEDURE FS_TO_CATS(P_ID IN NUMBER) IS
  
  ID_WFA NUMBER;
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  vStatus VARCHAR2(100);
  vDuration NUMBER;
  vDate DATE;
  vNumeroOdm VARCHAR2(25);
  vNumeroAdm VARCHAR2(25);
  
  BEGIN
    
    --se non si tratta di una complete o suspend esco subito
    select FS07_ACTIVITYSTATUS into vStatus from FS07_COMPLETE where MESSAGE_ID = P_ID;
    if vStatus not in ('suspended','complete') THEN
      RETURN;
    end if;


     SELECT SEQ_ID_WFA.NEXTVAL 
        INTO ID_WFA
        FROM DUAL;
  
      
      -- uso le property to table per proprieta da estrarre in auto 
      -- ATTENZIONE: se uso fs_property_to_table l'insert sulla tabella viene fatta li. dopo solo update
      UTL_TABLE.FS_PROPERTY_TO_TABLE('CT01_CATS','CT01_ID',p_id,ID_WFA);
      --insert into CT01_CATS(CT01_ID) VALUES (ID_WFA); --commentare questa riga se passati da fs_property_to_table

      --recupero variabili
      /* fa tutto il blex!
      select 24 * (FS07_ACTIVITY_END_TIME - FS07_ACTIVITY_START_TIME),FS07_ACTIVITY_END_TIME 
      into vDuration, vDate 
      from FS07_COMPLETE 
      where message_id = P_ID;

      Update CT01_CATS 
      SET CT01_DURATA = vDuration, 
      CT01_DATE = vDate 
      where CT01_ID = ID_WFA;
      */
            
      SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0'),
                XMLELEMENT("ID", ID_WFA)
              )
          INTO xml
          FROM dual; 
  
      UTIL_HTP.HTP_XML (xml);
      
      EXCEPTION WHEN others THEN
      
      err_code := SQLCODE;
      err_msg := substr(SQLERRM, 1, 4000);
             
      SELECT XMLELEMENT("RESPONSE",
                  XMLELEMENT("STATUS", err_code),
                  XMLELEMENT("ERROR", err_msg)
                )
             INTO xml
             FROM dual;            
          
      UTIL_HTP.HTP_XML (xml); 
      
  END;
  
  PROCEDURE MULTI_FS_TO_TRNOSVC(P_XML VARCHAR2) IS
  
  ID_WFA NUMBER;
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);

  mex XMLTYPE;
  v_temp XMLTYPE;
  idMessage VARCHAR2(50);
  countMex INTEGER;
  
  controlCount NUMBER;
  controlValue VARCHAR2(50);

  CURSOR cxml IS
  SELECT VALUE (xml_tag) xmlMex
  FROM TABLE (XMLSEQUENCE (EXTRACT (XMLTYPE(p_xml), '/Messages/ID'))) xml_tag;
  
  BEGIN
    
    SELECT 
      XMLELEMENT("RESPONSE", '')
    INTO xml
    FROM dual;

    FOR c IN cxml
    LOOP
      BEGIN

        SELECT EXTRACTVALUE (c.xmlMex, '/ID') 
        INTO idMessage
        FROM dual;
        
        --inserire IF per evitare di gestire le pratiche di consuntivazione non pertinenti
        controlCount := 0;
        controlValue := '';
        
        --cerco se c'è una xa_int_effettuato
        SELECT COUNT(MESSAGE_ID) into controlCount FROM FS09_COMPLETE_PROPERTY WHERE MESSAGE_ID = idMessage AND FS09_LABEL = 'xa_int_effettuato' AND ROWNUM = '1';
        IF controlCount > 0 THEN
          --prendo il valore
          SELECT TO_CHAR(FS09_VALUE) into controlValue FROM FS09_COMPLETE_PROPERTY WHERE MESSAGE_ID = idMessage AND FS09_LABEL = 'xa_int_effettuato' AND ROWNUM = '1';
          
          --se c'è controllo il valore per capire se contatore SOSTITUITO o SIGILLATO
          IF controlValue IN ('1','13') THEN
            SELECT SEQ_TRNOSVC_ID_WFA.NEXTVAL 
            INTO ID_WFA
            FROM DUAL;
    
            -- uso le property to table per tutte le tabelle di trn
            UTL_TABLE.FS_PROPERTY_TO_TABLE_TRN('TN06_WFM_RICNEW','TN06_ID_WFA',idMessage,ID_WFA,'Gas');
            -- ulteriori modifiche ed elaborazioni
            TN_WEBSERVICE.TRNOSVC_RETURN_MORE('TN06_WFM_RICNEW','TN06_ID_WFA',idMessage,ID_WFA,'Gas');
            -- setto le eventuali coordinate
            GEO_WEBSERVICE.COORD_FS_to_TRN_OSVC(idMessage,ID_WFA);
            
            --preparo la risposta positiva
            v_temp := xml;
             SELECT INSERTCHILDXML(
               v_temp, '/RESPONSE', 'TRNResponse', XMLType('<TRNResponse><ID_WFA>'|| ID_WFA ||'</ID_WFA><STATUS>0</STATUS></TRNResponse>') )
                 into xml
                 from dual;
          ELSE
            v_temp := xml;
            SELECT INSERTCHILDXML(
               v_temp, '/RESPONSE', 'TRNResponse', XMLType('<TRNResponse><ID_WFA>'|| idMessage ||'</ID_WFA><STATUS>1</STATUS><ERROR>No return needed on legacy.</ERROR></TRNResponse>') )
                 into xml
                 from dual;
          END IF;
          
        ELSE          
          v_temp := xml;
          SELECT INSERTCHILDXML(
               v_temp, '/RESPONSE', 'TRNResponse', XMLType('<TRNResponse><ID_WFA>'|| idMessage ||'</ID_WFA><STATUS>1</STATUS><ERROR>No activity type received in xa_int_effettuato.</ERROR></TRNResponse>') )
                 into xml
                 from dual;
                 
          TN_WEBSERVICE.LOG_ERROR(idMessage,'No activity type received in xa_int_effettuato.',xml.getClobVal(),'ConsuntivazioneOSVC','BLEX');
        END IF;

      EXCEPTION WHEN others THEN
        err_code := SQLCODE;
        err_msg := substr(SQLERRM, 1, 4000);  
        v_temp := xml;
        
        --ritorno l'ID con esito negativo
        SELECT INSERTCHILDXML(
          v_temp, '/RESPONSE', 'TRNResponse', XMLType('<TRNResponse><ID_WFA>'|| ID_WFA ||'</ID_WFA><STATUS>1</STATUS><ERROR>'||err_msg||'</ERROR></TRNResponse>') )
        into xml
        from dual;
        
        --loggo l'errore
        TN_WEBSERVICE.LOG_ERROR(idMessage,to_clob(err_msg),xml.getClobVal(),'ConsuntivazioneOSVC','BLEX');

      END;   
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Finito'); 
  
    UTIL_HTP.HTP_XML (xml);
  

  EXCEPTION WHEN others THEN

    err_code := SQLCODE;
    err_msg := substr(SQLERRM, 1, 4000);  
    
    SELECT 
      XMLELEMENT("RESPONSE",
        XMLELEMENT("STATUS", '1'),
        XMLELEMENT("ERROR", err_msg))
    INTO xml
    FROM dual;
    
    DBMS_OUTPUT.PUT_LINE(err_msg); 
    
    UTIL_HTP.HTP_XML (xml);
      
  END MULTI_FS_TO_TRNOSVC;

  PROCEDURE SD_TO_FS(P_ID IN NUMBER) IS
  
  FS_ID NUMBER;
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  
  BEGIN
      
      --goOn := 1;
  
      SELECT FS01_ACTIVITY_SEQ.NEXTVAL 
        INTO FS_ID
        FROM DUAL;
      
      -- ut03 blex
      UTL_TABLE.TABLE_TO_FS_PROPERTY('SD01_ANDATA', 'SD01_ID_WFA', p_id, FS_ID,'SAP-SD');

      -- update del bucket
      BLEX_WEBSERVICE.SET_BUCKET(FS_ID);
      
      SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0'),
                XMLELEMENT("ID", FS_ID)
              )
          INTO xml
          FROM dual; 
  
      UTIL_HTP.HTP_XML (xml);
      
      EXCEPTION WHEN others THEN
      
      err_code := SQLCODE;
      err_msg := substr(SQLERRM, 1, 4000);
             
      SELECT XMLELEMENT("RESPONSE",
                  XMLELEMENT("STATUS", err_code),
                  XMLELEMENT("ERROR", err_msg)
                )
             INTO xml
             FROM dual;            
          
      UTIL_HTP.HTP_XML (xml); 
      
      --HTP.P(SQLERRM);
  END SD_TO_FS;
  
  PROCEDURE NH_TO_FS(P_ID IN NUMBER) IS
  
    FS_ID NUMBER;
    xml   XMLTYPE;

    err_code  VARCHAR2(50);
    err_msg   VARCHAR2(4000);

    id_cont NUMBER;
    
  BEGIN
    
      --prendo il nuovo id per la tabella FS01
      SELECT FS01_ACTIVITY_SEQ.NEXTVAL 
      INTO FS_ID
      FROM DUAL;
        
      -- inserisco la proprietà della ODL nella tabella FS03_PROPERTY
      UTL_TABLE.TABLE_TO_FS_PROPERTY('NH01_ODI', 'NH01_ID_WFA', p_id, FS_ID,'NETH20');

      -- update del bucket
      BLEX_WEBSERVICE.SET_BUCKET(FS_ID);
      
      --più contatori acqua, per adesso prendo il primo se c'è
      SELECT COUNT(NH03_ID_WFA) into id_cont FROM NH03_CONTATORI WHERE NH03_ID_LINK = p_id AND NH03_NUM_SEQ_ELEMENTO = '1';
      IF id_cont > 0 THEN
        SELECT NH03_ID_WFA into id_cont FROM NH03_CONTATORI WHERE NH03_ID_LINK = p_id AND NH03_NUM_SEQ_ELEMENTO = '1';
        UTL_TABLE.TABLE_TO_FS_PROPERTY('NH03_CONTATORI', 'NH03_ID_WFA', id_cont, FS_ID,'NETH20');
      END IF;
       
      SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0'),
                XMLELEMENT("ID", FS_ID)
              )
          INTO xml
          FROM dual; 
    
      --rispondo con il risultato
      UTIL_HTP.HTP_XML (xml);
      
      EXCEPTION WHEN others THEN
      
      --prendo il messaggio di errore e lo restituisco
      err_code := SQLCODE;
      err_msg := substr(SQLERRM, 1, 4000);
             
      SELECT XMLELEMENT("RESPONSE",
                  XMLELEMENT("STATUS", err_code),
                  XMLELEMENT("ERROR", err_msg)
                )
             INTO xml
             FROM dual;            
      
      --rispondo con il risultato    
      UTIL_HTP.HTP_XML (xml); 

      DBMS_OUTPUT.PUT_LINE('--ERRORE - MSG:'|| err_msg);
      
  END;

  PROCEDURE FS_TO_SD(P_ID IN NUMBER) IS
  
  ID_WFA NUMBER;
  xml   XMLTYPE;
  goOn NUMBER;
  err_code  VARCHAR2(50);
  err_msg   VARCHAR2(4000);
  count_nd NUMBER;
  INTERNAL_ID NUMBER;
  
  BEGIN
  
     SELECT SD02_ID_SEQ.NEXTVAL 
        INTO ID_WFA
        FROM DUAL;
  
      
      -- uso le property to table per tutte le tabelle di SD
      UTL_TABLE.FS_PROPERTY_TO_TABLE('SD02_RITORNO_S','SD02_ID_WFA',p_id,ID_WFA);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('SD04_RITORNO_C','SD04_ID_WFA',p_id,ID_WFA);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('SD06_RITORNO_R','SD06_ID_WFA',p_id,ID_WFA);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('SD07_RITORNO_RI','SD07_ID_WFA',p_id,ID_WFA);
      UTL_TABLE.FS_PROPERTY_TO_TABLE('SD08_RITORNO_A','SD08_ID_WFA',p_id,ID_WFA);

      --setto manualmente le tabelle con una molteplicita
      --tabella sd03 note
      --TODO funzione su utl_table che prende property e inserisce riga
      --      Testo note commerciali (TDID = Z007) 000001 xa_note_richiesta
       SELECT SD03_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
      insert into SD03_RITORNO_N (SD03_ID_WFA,SD03_INTERNAL_ID,SD03_POSNR,SD03_TDID,SD03_NRIGA) VALUES (ID_WFA, INTERNAL_ID, '000000', 'Z007', '000001');
      UTL_TABLE.FS_PROPERTY_TO_ROW('SD03_RITORNO_N', 'SD03_TEXTLINE', 'SD03_INTERNAL_ID', 'xa_note_richiesta', NULL, p_id, INTERNAL_ID);
      --Testo appuntamento (TDID = ZAPP)  xa_note_appunt_anticipato
       SELECT SD03_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
      insert into SD03_RITORNO_N (SD03_ID_WFA,SD03_INTERNAL_ID,SD03_POSNR,SD03_TDID,SD03_NRIGA) VALUES (ID_WFA, INTERNAL_ID, '000000', 'ZAPP', '000002');
      UTL_TABLE.FS_PROPERTY_TO_ROW('SD03_RITORNO_N', 'SD03_TEXTLINE', 'SD03_INTERNAL_ID', 'xa_note_appunt_anticipato', NULL, p_id, INTERNAL_ID);
      --Note sospensione (TDID = ZSOS)  xa_mot_sosp
      SELECT SD03_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
      insert into SD03_RITORNO_N (SD03_ID_WFA,SD03_INTERNAL_ID,SD03_POSNR,SD03_TDID,SD03_NRIGA) VALUES (ID_WFA, INTERNAL_ID, '000000', 'ZSOS', '000003');
      UTL_TABLE.FS_PROPERTY_TO_ROW('SD03_RITORNO_N', 'SD03_TEXTLINE', 'SD03_INTERNAL_ID', 'xa_mot_sosp', NULL, p_id, INTERNAL_ID);
      --VBAK-ZZDANN = data sopralluogo + note annullamento (TDID = YDAN)  xa_causali_annullamento
      SELECT SD03_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
      insert into SD03_RITORNO_N (SD03_ID_WFA,SD03_INTERNAL_ID,SD03_POSNR,SD03_TDID,SD03_NRIGA) VALUES (ID_WFA, INTERNAL_ID, '000000', 'YDAN', '000004');
      UTL_TABLE.FS_PROPERTY_TO_ROW('SD03_RITORNO_N', 'SD03_TEXTLINE', 'SD03_INTERNAL_ID', 'xa_causali_annullamento', NULL, p_id, INTERNAL_ID);
      --<attesa info da Cervi>  xa_note_prs
      SELECT SD03_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
      insert into SD03_RITORNO_N (SD03_ID_WFA,SD03_INTERNAL_ID,SD03_POSNR,SD03_TDID,SD03_NRIGA) VALUES (ID_WFA, INTERNAL_ID, '000000', '', '000005');
      UTL_TABLE.FS_PROPERTY_TO_ROW('SD03_RITORNO_N', 'SD03_TEXTLINE', 'SD03_INTERNAL_ID', 'xa_note_prs', NULL, p_id, INTERNAL_ID);
      --<attesa info da Cervi>  xa_note_opere_murarie
      SELECT SD03_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
      insert into SD03_RITORNO_N (SD03_ID_WFA,SD03_INTERNAL_ID,SD03_POSNR,SD03_TDID,SD03_NRIGA) VALUES (ID_WFA, INTERNAL_ID, '000000', '', '000006');
      UTL_TABLE.FS_PROPERTY_TO_ROW('SD03_RITORNO_N', 'SD03_TEXTLINE', 'SD03_INTERNAL_ID', 'xa_note_opere_murarie', NULL, p_id, INTERNAL_ID);
      --<attesa info da Cervi>  xa_note_autorizzazioni
      SELECT SD03_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
      insert into SD03_RITORNO_N (SD03_ID_WFA,SD03_INTERNAL_ID,SD03_POSNR,SD03_TDID,SD03_NRIGA) VALUES (ID_WFA, INTERNAL_ID, '000000', '', '000007');
      UTL_TABLE.FS_PROPERTY_TO_ROW('SD03_RITORNO_N', 'SD03_TEXTLINE', 'SD03_INTERNAL_ID', 'xa_note_autorizzazioni', NULL, p_id, INTERNAL_ID);
      --<attesa info da Cervi>  xa_note_autorizzazioni_ulteriori
      SELECT SD03_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
      insert into SD03_RITORNO_N (SD03_ID_WFA,SD03_INTERNAL_ID,SD03_POSNR,SD03_TDID,SD03_NRIGA) VALUES (ID_WFA, INTERNAL_ID, '000000', '', '000008');
      UTL_TABLE.FS_PROPERTY_TO_ROW('SD03_RITORNO_N', 'SD03_TEXTLINE', 'SD03_INTERNAL_ID', 'xa_note_autorizzazioni_ulteriori', NULL, p_id, INTERNAL_ID);
      --<attesa info da Cervi>  xa_note_subordino
      SELECT SD03_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
      insert into SD03_RITORNO_N (SD03_ID_WFA,SD03_INTERNAL_ID,SD03_POSNR,SD03_TDID,SD03_NRIGA) VALUES (ID_WFA, INTERNAL_ID, '000000', '', '000009');
      UTL_TABLE.FS_PROPERTY_TO_ROW('SD03_RITORNO_N', 'SD03_TEXTLINE', 'SD03_INTERNAL_ID', 'xa_note_subordino', NULL, p_id, INTERNAL_ID);
      --Testo "Oggetto" (TDID = Y001) xa_descrizione_ogg_lav
      SELECT SD03_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
      insert into SD03_RITORNO_N (SD03_ID_WFA,SD03_INTERNAL_ID,SD03_POSNR,SD03_TDID,SD03_NRIGA) VALUES (ID_WFA, INTERNAL_ID, '000000', 'Y001', '000010');
      UTL_TABLE.FS_PROPERTY_TO_ROW('SD03_RITORNO_N', 'SD03_TEXTLINE', 'SD03_INTERNAL_ID', 'xa_descrizione_ogg_lav', NULL, p_id, INTERNAL_ID);
      --Testo note preventivo" (TDID = Z006)  xa_note_preventivo
      SELECT SD03_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
      insert into SD03_RITORNO_N (SD03_ID_WFA,SD03_INTERNAL_ID,SD03_POSNR,SD03_TDID,SD03_NRIGA) VALUES (ID_WFA, INTERNAL_ID, '000000', 'Z006', '000011');
      UTL_TABLE.FS_PROPERTY_TO_ROW('SD03_RITORNO_N', 'SD03_TEXTLINE', 'SD03_INTERNAL_ID', 'xa_note_preventivo', NULL, p_id, INTERNAL_ID);
      --Testo note interne (TDID = 0004)  xa_note_interne
      SELECT SD03_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
      insert into SD03_RITORNO_N (SD03_ID_WFA,SD03_INTERNAL_ID,SD03_POSNR,SD03_TDID,SD03_NRIGA) VALUES (ID_WFA, INTERNAL_ID, '000000', '0004', '000012');
      UTL_TABLE.FS_PROPERTY_TO_ROW('SD03_RITORNO_N', 'SD03_TEXTLINE', 'SD03_INTERNAL_ID', 'xa_note_interne', NULL, p_id, INTERNAL_ID);

      FOR count_nd IN 1..10
      LOOP
        --funzione su utl_table che accetta un indice per le mappature
        SELECT SD05_ID_SEQ.NEXTVAL 
        INTO INTERNAL_ID
        FROM DUAL;
        UTL_TABLE.FS_PROPERTY_TO_TABLE_INDEX('SD05_RITORNO_CD','SD05_INTERNAL_ID',p_id,INTERNAL_ID,count_nd);
      END LOOP;

            
      SELECT XMLELEMENT("RESPONSE",
                XMLELEMENT("STATUS", '0'),
                XMLELEMENT("ID", ID_WFA)
              )
          INTO xml
          FROM dual; 
  
      UTIL_HTP.HTP_XML (xml);
      
      EXCEPTION WHEN others THEN
      
      err_code := SQLCODE;
      err_msg := substr(SQLERRM, 1, 4000);
             
      SELECT XMLELEMENT("RESPONSE",
                  XMLELEMENT("STATUS", err_code),
                  XMLELEMENT("ERROR", err_msg)
                )
             INTO xml
             FROM dual;            
          
      UTIL_HTP.HTP_XML (xml); 
      
  END FS_TO_SD;


  PROCEDURE SET_BUCKET(FS_ID IN NUMBER) IS
  L_BUCKET FS01_ACTIVITY.FS01_COMMAND_EXTERNALID%TYPE;
  BEGIN
    dbms_output.put_line('- Assegnazione bucket '||FS_ID||' -');
    IF FS_ID is not null THEN
      select GET_BUCKET(case when FS01_ORIGINE in ('SAP-PM-O', 'SAP-PM-A') then 'SAP' else FS01_ORIGINE end, FS01_TYPE_SRC, FS01_ZIP, FS01_STATE)
      into L_BUCKET
      from FS01_ACTIVITY
      where FS01_ID = FS_ID;
      dbms_output.put_line('- calcolato bucket '||L_BUCKET||' - OK');
      UPDATE FS01_ACTIVITY
      SET FS01_COMMAND_EXTERNALID = L_BUCKET
      WHERE FS01_ID = FS_ID;
      dbms_output.put_line('- Assegnazione bucket '||FS_ID||' - OK');
    END IF;
    
  EXCEPTION WHEN OTHERS THEN
    dbms_output.put_line('- Assegnazione bucket '||FS_ID||' - KO');
  END SET_BUCKET;

END BLEX_WEBSERVICE;