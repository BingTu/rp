CREATE OR REPLACE PROCEDURE MES1.g_machine_sp_worktype_web (
    mydata        IN     VARCHAR2,
    g_stationno   IN     VARCHAR2,
    res              OUT VARCHAR2)
IS
    --++V MODIFY BY SHWW 下午 05:07 2003/10/9
    --++D WRITE BY BILL  上午 09:17 2003/08/25
    --++E EDIT BY BILL 下午 02:45 2003/10/16  增加整機備料和整機備料中下料
    --++E EDIT BY BILL  上午 10:39 2003/11/06  修改提示信息
    --++E EDIT BY BILL  上午 11:16 2003/11/06  增加付傳入几SP的參數L_AP_STATION
    --++E EDIT BY LFL   下午 21:00:00 2004/02/25 增加換料模式
    --++E EDIT BY LFL  2004/3/11 08:10:00 整機出下料加上確認碼
    --++E EDIT BY LFL  2004/3/11 16:50:00 換料以掉循環與猴缺料處渚
    --++E EDIT BY LFL  2004/3/16 20:15:00  統一確認碼為CONFIRM-S
    --++M EDIT BY LFL  2004/3/19 18:00:00  修改提示信息
    --++M MODIFY BY LFL 2004/4/1
    --++M MODIFY BY LFL 2004/4/12 修改換料亟對所輸序號的機出貂行判斷
    --M MODIFY BY LFL 2004/10/19 17:30:00  判斷上料﹐下料時掃入的機出號是否正確
    --++M MODIDFY BY ELI 2005/10/06 對換料作業調整；將CHECK_FEEDERNO放到MES1.pkg_smt_scan_web_check.CHECK_STATION_MACHINE_WEB_WEB前面
    --++M MODIFY BY SYANT_WANGJUN 20070428 加入對AOI資料的支持,作業代碼為﹕ACTION-AOI
    --++M MODIFY BY SYANT_WANGJUN 20070501 加入在線對料的功能,作業代碼為﹕ ACTION-M-K
    --++M MODIFY BY SYANT_WANGJUN 20070502 加入對換料前Kitting預警,作業代碼為﹕ACTION-M-P
    --++M MODIFY BY LS 20110911  加入刮刀上線功能，作業代碼為﹕ACTION-M-SO
    --++M MODIFY BY  LS 20110911 加入刮刀下線功能， 作業代碼為﹕ CTION-M-SF
    --++M MODIFY BY tommis 20210610  加入钢网上線功能，作業代碼為﹕ACTION-M-ST
    --++M MODIFY BY  tommis 20210610 加入钢网下線功能， 作業代碼為﹕ ACTION-M-SN
    --++M MODIFY BY WY  20131023 加入FEEDER在線鎖定功能，作業代碼為： ACTION-M-FL
    --++M MODIFY BY WY  20131023 加入FEEDER在線解鎖功能，作業代碼為： ACTION-M-FU
    l_next_input           VARCHAR2 (50);
    l_this_input           VARCHAR2 (50);
    l_sequence             VARCHAR2 (2);
    l_action_code          VARCHAR2 (50);
    l_machine1             VARCHAR2 (50);
    l_reslt_check          VARCHAR2 (20);
    l_track                VARCHAR2 (1);
    l_track_tmp            VARCHAR2 (1);
    l_machine              mes4.r_station_wip.station%TYPE;
    l_ap_station           mes4.r_station_wip.station%TYPE;
    --The global parameter
    l_feeder               mes4.r_station_wip.feeder_no%TYPE;
    l_slot                 mes4.r_station_wip.slot_no%TYPE;
    l_emp                  mes1.c_emp.emp_no%TYPE;
    l_ap_emp               mes1.c_emp.emp_no%TYPE;
    L_CHECK_emp             mes1.c_emp.emp_no%TYPE;
    l_travelsn             mes4.r_station_temp.travel_sn%TYPE;
    l_work_flag            mes4.r_tr_sn.work_flag%TYPE;
    l_location_flag        mes4.r_tr_sn.location_flag%TYPE;
    l_slot_temp            mes4.r_station_wip.slot_no%TYPE;
    --l_temp_machine         mes4.r_station_wip.station%TYPE;
    --Add this param just for KP check... ...
    l_temp_slot            mes4.r_station_wip.slot_no%TYPE;
    --Add this param just for KP check... ...
    l_temp_trsn            mes4.r_station_wip.tr_sn%TYPE;
    l_tr_sn                mes4.r_tr_sn.tr_sn%TYPE;
    l_wo_work_flag         mes4.r_wo_base.work_flag%TYPE;
    l_tr_sn_temp           mes4.r_tr_sn.tr_sn%TYPE;
    user_cusor             mytest_package.testcursor;
    --Add this param just for kp check... ...

    exp1                   EXCEPTION;
    exp2                   EXCEPTION;
    exception_a            EXCEPTION;
    exception_b            EXCEPTION;
    l_exit                 EXCEPTION;
    ---
    tmp                    VARCHAR2 (250);
    tmp1                   VARCHAR2 (50);
    tmp2                   VARCHAR2 (25);
    tmp3                   VARCHAR2 (25);
    i                      NUMBER;
    j                      NUMBER;
    k                      NUMBER;
    tmp_tmp                NUMBER;          --Add a global number param... ...
    myprogram              VARCHAR2 (25);
    l_wo                   VARCHAR2 (12);
    mystation              VARCHAR2 (25);
    myinspect              VARCHAR2 (25);
    mytotal                VARCHAR2 (25);
    myship                 VARCHAR2 (25);
    myserial               VARCHAR2 (25);
    mylot                  VARCHAR2 (25);
    mypcb                  VARCHAR2 (25);
    myfilename             VARCHAR2 (50);
    mypanel                VARCHAR2 (25);
    myflag                 VARCHAR2 (25);
    tmp_check_emp_value    VARCHAR2 (50);              --add by wyz 2008/06/06
    i_temp_emp_privilage   NUMBER;                     --add by wyz 2008/06/06
    l_line                 VARCHAR2 (20);
    tmp_check_slot         VARCHAR2 (50);
    l_next_station         VARCHAR2 (30);
    --var_smtcode            VARCHAR2 (50);
    -- var_replace_kp         VARCHAR2 (50);
    --var_kp_no              VARCHAR2 (50);
    l_count                NUMBER;
    l_count1               NUMBER;
    l_temp_new_trsn        mes4.r_station_wip.tr_sn%TYPE;
    --add by wyz 2008/06/16
    l_temp_old_trsn        mes4.r_station_wip.tr_sn%TYPE;
    --add by lc
    tmp_check_mfr_emp      VARCHAR2 (10);
    --add by wyz 2008/06/16

    --add by Hardy 2011/08/19  kitting call material
    l_temp_slot_cm         VARCHAR2 (250);
    l_temp_trsn_cm         VARCHAR2 (250);
    l_temp_slot_cm_all     VARCHAR2 (250);
    l_temp_trsn_cm_all     VARCHAR2 (250);
    l_vwo_count            NUMBER;
    --add by hardy 2011/08/22  solder
    l_new_wo               VARCHAR2 (12);
    l_old_wo               VARCHAR2 (12);
    l_new_wo1              VARCHAR2 (12);
    l_p_version            mes1.c_solder_config.p_version%TYPE;
    l_station              mes4.r_tr_sn_wip.station%TYPE;
    ---add by LS  20110911 scraper
    l_wo_temp              VARCHAR2 (12);
    l_alarm_check_tray     VARCHAR2 (12);
    l_kitfeederno          VARCHAR2 (20);
    l_p_no                 VARCHAR2 (20);
    ERROR_CODE             VARCHAR2 (100);
    g_tr_sn                VARCHAR2 (100);
    l_use_flag             VARCHAR2 (50);
    l_error_desc           VARCHAR2 (50);
    --ADD BY CMS FOR CALL_MATERIAL--
    l_pno                  VARCHAR2 (25);
    l_temp_machine         VARCHAR2 (250);
    l_smt_emp              VARCHAR2 (20);
    l_kitting_emp          VARCHAR2 (20);
    l_newdata              VARCHAR2 (50);
    l_trans_data           VARCHAR2 (50);
    l_trsn_wip             VARCHAR2 (20);
    l_alarm_flag           VARCHAR2 (1);
    l_f_priority_level     VARCHAR2 (10);
    l_f_errdesc            VARCHAR2 (20);
    l_f_count              NUMBER;
    l_kpno                 VARCHAR (50);
    l_slot_no              VARCHAR2 (20);
    l_is_apmachine         VARCHAR2 (5);
    l_process              VARCHAR2 (5);
    l_process_flag         VARCHAR2 (5);
    l_res                  VARCHAR2 (2000);

    CURSOR get_check_emp_value IS
        SELECT function_value1, function_value2
          FROM mes1.c_program_parameter
         WHERE     program_type = 'SP'
               AND program_name = 'G_MACHINE_SP_WORKTYPE'
               AND function_name = 'ACTION-M-H'
               AND function_object = 'CHECK-EMP'
               AND data1 = 'NORMAL'
               AND ROWNUM = 1;

    ---
    CURSOR this_input IS
        SELECT data6, data3
          FROM mes4.r_ap_temp
         WHERE     data1 = 'SCADA-GW28'
               AND data2 = g_stationno
               AND data3 IN
                       (SELECT MAX (TO_NUMBER (data3))
                          FROM mes4.r_ap_temp
                         WHERE data1 = 'SCADA-GW28' AND data2 = g_stationno);

    -------MODIFY BY LFL

    --- add by syant_wangjun 20070425
    CURSOR get_aoi_config IS
        SELECT data8,
               data9,
               data11,
               data12,
               data13,
               data14,
               data15
          FROM mes4.r_ap_temp
         WHERE     data1 = 'SCADA-GW28'
               AND data2 = g_stationno
               AND data4 = 'AOI CONFIG'
               AND ROWNUM = 1;

    --- add by syant_wangjun 20070425

    --(TO_NUMBER(DATA3))
    CURSOR old_trsn (old_tr_sn IN VARCHAR2)
    IS
        SELECT work_flag, location_flag
          FROM mes4.r_tr_sn
         WHERE tr_sn = old_tr_sn;

    ----MODIFY BY LFL 2004/4/21
    CURSOR slot_wip IS
        SELECT slot_no
          FROM mes4.r_station_wip
         WHERE     station = l_machine
               AND tr_sn IS NULL
               AND slot_no LIKE mydata || '-%';

    CURSOR slot_track_wip IS
        SELECT slot_no
          FROM mes4.r_station_wip
         WHERE station = l_machine AND slot_no LIKE mydata || '-%';

    CURSOR slot_temp IS
        SELECT slot_no
          FROM mes4.r_station_temp
         WHERE     travel_sn = l_travelsn
               AND tr_sn IS NULL
               AND slot_no LIKE mydata || '-%';

    CURSOR slot_track_temp IS
        SELECT slot_no
          FROM mes4.r_station_temp
         WHERE travel_sn = l_travelsn AND slot_no LIKE mydata || '-%';

    CURSOR slot_track IS
        SELECT data5
          FROM mes4.r_ap_temp
         WHERE     data1 = 'SCADA-GW28'
               AND data2 = g_stationno
               AND data4 = 'SLOT NO'
               AND data6 = 'FEEDER NO'
               AND data5 LIKE '%-' || l_track || '%';

    CURSOR slot_track_tmp IS
        SELECT data5
          FROM mes4.r_ap_temp
         WHERE     data1 = 'SCADA-GW28'
               AND data2 = g_stationno
               AND data4 = 'SLOT NO/END'
               AND data6 = 'FEEDER NO'
               AND data5 LIKE '%-' || l_track || '%';

    CURSOR temp_track IS
        SELECT data5
          FROM mes4.r_ap_temp
         WHERE     data1 = 'SCADA-GW28'
               AND data2 = g_stationno
               AND data4 = 'SLOT NO/END'
               AND data6 = 'FEEDER NO'
               AND data5 LIKE '%-%';

    CURSOR wip_track IS
        SELECT data5
          FROM mes4.r_ap_temp
         WHERE     data1 = 'SCADA-GW28'
               AND data2 = g_stationno
               AND data4 = 'SLOT NO'
               AND data6 = 'FEEDER NO'
               AND data5 LIKE '%-%';

    ---------------------------------FOR SCRAPER  20110911 --------

    CURSOR check_scraper_in_station IS
        SELECT fixture_sn, wo
          FROM mes4.r_fixture_wip
         WHERE fixture_sn = UPPER (mydata) AND station_name = l_ap_station;

    CURSOR find_scraper_wo IS
        SELECT DISTINCT wo
          FROM mes4.r_station_wip
         WHERE station = UPPER (l_ap_station);

    CURSOR check_scraper_exist IS
        SELECT fixture_sn
          FROM mes1.c_fixture_base
         WHERE fixture_sn = UPPER (mydata) AND ROWNUM = 1;

    ----------------------------END FOR SCRAPER  20110911-----------

    ----add  by hardy 2011/08/23
    CURSOR check_solder_travel_sn IS
        SELECT wo
          FROM mes4.r_travel_sn
         WHERE travel_sn = UPPER (mydata);

    CURSOR check_solder_travel_station IS
        SELECT wo
          FROM mes4.r_travel_sn
         WHERE travel_sn = UPPER (mydata) AND station = UPPER (l_ap_station);

    CURSOR check_solderwip IS
        SELECT tr_sn
          FROM mes4.r_solder_wip
         WHERE tr_sn = UPPER (mydata) OR station = l_ap_station;

    CURSOR check_solder_in_station IS
        SELECT tr_sn, wo
          FROM mes4.r_tr_sn_wip
         WHERE station = UPPER (l_ap_station) AND tr_sn = UPPER (mydata);

    CURSOR check_solder_double_in_station IS
        SELECT tr_sn, wo
          FROM mes4.r_tr_sn_wip
         WHERE tr_sn = UPPER (mydata) AND work_flag = '1';

    CURSOR check_solder_version IS
        SELECT a.p_version
          FROM mes1.c_solder_config a, mes4.r_wo_base b, mes4.r_tr_sn_wip c
         WHERE     c.tr_sn = l_tr_sn
               AND a.kp_no = c.kp_no
               AND b.wo = l_new_wo
               AND a.p_no = b.p_no
               AND a.p_version = b.p_version;

    CURSOR get_solder_tr_sn_new_wo IS
        SELECT data9, data10
          FROM mes4.r_ap_temp
         WHERE     data2 = g_stationno
               AND data1 = 'SCADA-GW28'
               AND data5 = 'ACTION-M-SE';

    CURSOR check_trsn_status                  --ADD BY DZL FOR SOLDER 20101123
                             IS
        SELECT tr_sn
          FROM mes4.r_tr_sn
         WHERE tr_sn = UPPER (mydata) AND ROWNUM = 1;

    CURSOR check_trsn_solder                  --ADD BY DZL FOR SOLDER 20101123
                             IS
        SELECT tr_sn
          FROM mes4.r_solder_detail
         WHERE tr_sn = UPPER (mydata) AND ROWNUM = 1;

    ---add by hardy 2011 08 23 ---
    CURSOR call_material01 IS
        SELECT *
          FROM (SELECT MAX (m.slot_no)     AS slot_no
                  FROM mes4.r_station_wip m, mes4.r_station_wip n
                 WHERE     m.wo = n.wo
                       AND m.station = n.station
                       AND n.tr_sn = mydata
                       AND m.slot_no < n.slot_no
                       AND m.slot_no LIKE SUBSTR (n.slot_no, 0, 1) || '%'
                       AND m.emp_no LIKE '+%'
                UNION
                SELECT MIN (m.slot_no)
                  FROM mes4.r_station_wip m, mes4.r_station_wip n
                 WHERE     m.wo = n.wo
                       AND m.station = n.station
                       AND n.tr_sn = mydata
                       AND m.slot_no > n.slot_no
                       AND m.slot_no LIKE SUBSTR (n.slot_no, 0, 1) || '%'
                       AND m.emp_no LIKE '+%')
         WHERE slot_no IS NOT NULL;

    CURSOR call_material02 IS
        SELECT a.tr_sn AS tr_sn, b.slot_no AS slot_no
          FROM mes4.r_tr_sn_wip  a,
               (SELECT p.*
                  FROM mes4.r_station_wip  p,
                       (  SELECT m.wo, m.station, MIN (m.slot_no) AS slot_no
                            FROM mes4.r_station_wip m, mes4.r_station_wip n
                           WHERE     m.wo = n.wo
                                 AND m.station = n.station
                                 AND n.tr_sn = mydata
                                 AND m.slot_no > n.slot_no
                                 AND m.slot_no LIKE
                                         SUBSTR (n.slot_no, 0, 1) || '%'
                        GROUP BY m.wo, m.station
                        UNION
                          SELECT m.wo, m.station, MAX (m.slot_no) AS slot_no
                            FROM mes4.r_station_wip m, mes4.r_station_wip n
                           WHERE     m.wo = n.wo
                                 AND m.station = n.station
                                 AND n.tr_sn = mydata
                                 AND m.slot_no < n.slot_no
                                 AND m.slot_no LIKE
                                         SUBSTR (n.slot_no, 0, 1) || '%'
                        GROUP BY m.wo, m.station) q
                 WHERE     p.wo = q.wo
                       AND p.station = q.station
                       AND p.slot_no = q.slot_no) b
         WHERE     a.wo = b.wo
               AND a.station = b.station
               AND a.kp_no = b.kp_no
               AND work_flag = '0';

    CURSOR call_material03 IS
        SELECT n.tr_sn || '-SMT'     AS tr_sn
          FROM mes4.r_station_wip m, mes4.r_tr_sn_wip n, mes1.c_smt_ap_list l
         WHERE     m.wo = n.wo
               AND m.station = n.station
               AND m.smt_code = l.smt_code
               AND n.kp_no IN l.kp_no
               AND n.work_flag = '0'
               AND n.station LIKE '%AH_'
               AND n.emp_no NOT LIKE '+%'
               AND m.tr_sn = mydata
        UNION
        SELECT m.data5 || '-KIT'     AS tr_sn
          FROM mes4.r_job_record   m,
               mes4.r_station_wip  n,
               mes4.r_tr_sn        l,
               mes1.c_smt_ap_list  p
         WHERE     m.machine = n.station
               AND m.data3 = n.wo
               AND m.CATEGORY = 'WIP_CONTROL'
               AND m.data6 = 'DELETE'
               AND n.smt_code = p.smt_code
               AND n.kp_no = p.kp_no
               AND m.data5 = l.tr_sn
               AND l.location_flag = '1'
               AND l.work_flag = '0'
               AND n.tr_sn = mydata;

    CURSOR call_material04 IS
        SELECT slot_no
          FROM mes4.r_station_wip
         WHERE     station = l_ap_station
               AND station LIKE '%AH_'
               AND SUBSTR (emp_no, 1, 1) = '+';

    CURSOR call_material05 IS
        SELECT m.checkout_qty
          FROM mes4.r_wo_request m, mes4.r_station_wip n
         WHERE     m.wo = n.wo
               AND m.cust_kp_no = n.kp_no
               AND m.checkout_qty >= m.wo_request
               AND n.tr_sn = mydata;

    CURSOR call_material06 IS
        SELECT a.checkout_qty
          FROM (SELECT SUM (x.wo_request)       wo_request,
                       SUM (x.checkout_qty)     checkout_qty
                  FROM mes4.r_wo_request x, mes4.r_station_wip l
                 WHERE     x.wo IN
                               (SELECT t_wo
                                  FROM mes4.r_v_wo
                                 WHERE v_wo IN
                                           (SELECT v_wo
                                              FROM mes4.r_v_wo         m,
                                                   mes4.r_station_wip  n
                                             WHERE     m.t_wo = n.wo
                                                   AND n.tr_sn = mydata))
                       AND x.cust_kp_no = l.kp_no
                       AND l.tr_sn = mydata) a
         WHERE a.checkout_qty >= a.wo_request;
---end
BEGIN
    --第一步﹕初始化必要的參量... ...
    myprogram := ' ';
    mystation := ' ';
    myinspect := ' ';
    mytotal := ' ';
    myship := ' ';
    myserial := ' ';
    mylot := ' ';
    mypcb := ' ';
    myfilename := ' ';
    mypanel := ' ';
    myflag := ' ';


    SELECT COUNT (1)
      INTO L_COUNT
      FROM MES4.R_LOGIN_webstation
     WHERE     STATION_NONEW = g_stationno
           AND (   INSTR (STATION_NAME, 'AP') > 0
                OR INSTR (STATION_NAME, 'LM') > 0);

    IF L_COUNT > 0
    THEN
        l_is_apmachine := 'Y';
    END IF;

    ---准備員工號...
    SELECT data5
      INTO l_emp
      FROM mes4.r_ap_temp
     WHERE     data1 = 'SCADA-GW28'
           AND data2 = g_stationno
           AND data4 = 'EMP'
           AND ROWNUM = 1;

    SELECT MES1.get_PROCESS_FLAG_new (g_stationno, '')
      INTO l_process
      FROM DUAL;

    --准備隨參數傳入的機台名稱...

    SELECT COUNT (1)
      INTO l_count
      FROM MES4.R_LOGIN_webstation
     WHERE STATION_NONEW = g_stationno AND ROWNUM = 1;

    IF l_count > 0
    THEN
        SELECT station_name
          INTO l_ap_station
          FROM MES4.R_LOGIN_webstation
         WHERE STATION_NONEW = g_stationno AND ROWNUM = 1;
    ELSE
        --res:='没有配置机台信息';
        res := 'MSG-T00001';
        RAISE l_exit;
    END IF;

    --add by andy 20160102 ,UPDATE last used time--
    UPDATE MES4.R_LOGIN_webstation
       SET IN_TIME = SYSDATE
     WHERE STATION_NONEW = g_stationno;

    COMMIT;

    --檢查機臺是否被鎖　by yinjun 20131015
    SELECT COUNT (*)
      INTO l_count
      FROM mes1.c_auto_smtstop_detail
     WHERE lockflag = '1' AND stationname = l_ap_station;

    IF l_count > 0
    THEN
        SELECT COUNT (*)
          INTO l_count
          FROM mes4.r_ap_temp
         WHERE     data1 = 'SCADA-GW28'
               AND data2 = g_stationno
               AND data4 = 'ACTION CODE'
               AND data5 = 'ACTION-M-UL';

        IF l_count = 0 AND mydata <> 'ACTION-M-UL'
        THEN
            --res :='LOCK! 此機臺被鎖,請找IPQC確認再掃描解鎖代碼！';
            res := 'SCM-T03369:';
            RAISE l_exit;
        END IF;

        IF mydata = 'ACTION-M-UL'
        THEN
            l_next_input := 'UNLOCK IPQC EMP';

            INSERT INTO mes4.r_ap_temp (data1,
                                        data2,
                                        data3,
                                        data4,
                                        data5,
                                        data6,
                                        data7,
                                        work_time)
                 VALUES ('SCADA-GW28',
                         g_stationno,
                         '2',
                         'ACTION CODE',
                         mydata,
                         l_next_input,
                         '0',
                         SYSDATE);

            COMMIT;

            DELETE mes4.r_ap_temp
             WHERE     data1 = 'SCADA-GW28'
                   AND data2 = g_stationno
                   AND data6 <> 'ACTION CODE'
                   AND data5 <> 'ACTION-M-UL';

            COMMIT;
            res := 'OK ACTION CODE';
            RAISE l_exit;
        ELSE
            --check mydata 工號 是否有權限！
            SELECT COUNT (*)
              INTO l_count
              FROM mes1.c_emp
             WHERE emp_password = mydata;

            IF l_count > 0
            THEN
                SELECT emp_no
                  INTO tmp2
                  FROM mes1.c_emp
                 WHERE emp_password = mydata;
            ELSE
                --res := '此工號無效！，請重新掃描！';
                res := 'SCM-T03097';
                RAISE l_exit;
            END IF;

            SELECT COUNT (*)
              INTO l_count
              FROM mes1.c_ap_config
             WHERE     ap_name = 'SMT'
                   AND function_name = 'AUTOSMTSTOP_UNLOCK'
                   AND emp_no = tmp2;

            IF l_count > 0
            THEN
                UPDATE mes1.c_auto_smtstop_detail
                   SET unlockemp = tmp2, unlocktime = SYSDATE, lockflag = '0'
                 WHERE lockflag = '1' AND stationname = l_ap_station;

                COMMIT;

                DELETE mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data3 <> 1;

                COMMIT;
                res := 'SCM-T03371';
                RAISE l_exit;
            ELSE
                res := 'SCM-T03370';
                RAISE l_exit;
            END IF;
        END IF;
    END IF;

    --抓取換料是否CHECK SLOT 參數
    SELECT COUNT (program_name)
      INTO l_count
      FROM mes1.c_program_parameter
     WHERE     program_type = 'SP'
           AND program_name = 'G_MACHINE_SP_WORKTYPE'
           AND function_name = 'ACTION-M-H'
           AND function_object = 'CHECK-SLOT'
           AND data1 = 'NORMAL';

    IF l_count = 0
    THEN
        tmp_check_slot := 'N';
    ELSE
        SELECT function_value1
          INTO tmp_check_slot
          FROM mes1.c_program_parameter
         WHERE     program_type = 'SP'
               AND program_name = 'G_MACHINE_SP_WORKTYPE'
               AND function_name = 'ACTION-M-H'
               AND function_object = 'CHECK-SLOT'
               AND data1 = 'NORMAL';
    END IF;

    ------SMT 物料預警 IPQC CHECK  Ryan 20120416 -------
    SELECT COUNT (program_name)
      INTO l_count
      FROM mes1.c_program_parameter
     WHERE     program_type = 'SP'
           AND program_name = 'G_MACHINE_SP_WORKTYPE'
           AND function_name = 'ACTION-M-AC'
           AND function_object = 'SMT-ALARM-CHECK-TRAY'
           AND data1 = 'NORMAL';

    IF l_count = 0
    THEN
        l_alarm_check_tray := 'N';
    ELSE
        SELECT function_value1
          INTO l_alarm_check_tray
          FROM mes1.c_program_parameter
         WHERE     program_type = 'SP'
               AND program_name = 'G_MACHINE_SP_WORKTYPE'
               AND function_name = 'ACTION-M-AC'
               AND function_object = 'SMT-ALARM-CHECK-TRAY'
               AND data1 = 'NORMAL';
    END IF;

    --記算步驟號和本次的操作名稱...
    OPEN this_input;

    FETCH this_input INTO l_this_input, l_sequence;

    IF this_input%NOTFOUND
    THEN
        CLOSE this_input;

        RAISE exp1;
    END IF;

    CLOSE this_input;

    --THE ONLY SWITCH,FIRST SECTION...
    IF l_this_input = 'ACTION CODE'
    THEN
        IF mydata = 'ACTION-M-A'
        THEN
            l_next_input := 'TRAVEL SN WO';
        ELSIF mydata = 'ACTION-M-B'
        THEN
            l_next_input := 'MACHINE';
        ELSIF mydata = 'ACTION-M-M'                      --中途换工单打,再切回来,系统资料有问题
        THEN
            l_next_input := 'MACHINE';
        ELSIF mydata = 'ACTION-M-C'
        THEN
            l_next_input := 'TR SN';
        ELSIF mydata = '~ACTION-M-D'
        THEN
            l_next_input := 'CONFIRM CODE';
        ELSIF mydata = 'ACTION-M-E'
        THEN
            l_next_input := 'CONFIRM CODE';
        ELSIF mydata = 'ACTION-AOI'                 --syant_wangjun for aoi...
        THEN
            l_next_input := 'AOI CONFIG';
        ELSIF mydata = 'ACTION-M-F'
        THEN
            l_next_input := 'TRAVEL SN WO';
        ELSIF mydata = 'ACTION-M-FQ'
        THEN
            l_next_input := 'TRAVEL SN WO';
        ELSIF mydata = 'ACTION-M-G'
        THEN
            l_next_input := 'TR SN';
        ELSIF mydata = 'ACTION-M-H'
        THEN
            IF tmp_check_slot = 'Y'
            THEN
                SELECT COUNT (1)
                  INTO L_COUNT
                  FROM MES4.R_LOGIN_webstation
                 WHERE     STATION_NONEW = g_stationno
                       AND (   INSTR (STATION_NAME, 'AP') > 0
                            OR INSTR (STATION_NAME, 'LM') > 0);

                IF L_COUNT > 0
                THEN
                    IF INSTR (l_ap_station, 'LM') > 0
                    THEN
                        l_next_input := 'NEW TR SN';
                    ELSE
                        l_next_input := 'OLD TR SN';
                    END IF;

                    --                  l_next_input := 'OLD TR SN';
                    l_is_apmachine := 'Y';
                ELSE
                    l_next_input := 'SLOT NO';
                END IF;
            ELSE
                l_next_input := 'OLD TR SN';
            END IF;
        ELSIF mydata = 'ACTION-M-K'
        THEN                                  --syant_wangjun for kp check ...
            l_next_input := 'MACHINE';
        ELSIF mydata = 'ACTION-M-SA'              ----添加錫膏作業模式 by dzl 20101123
        THEN
            l_next_input := 'TR SN';
        ELSIF mydata = 'ACTION-M-SB'                              ----錫膏上線作業模式
        THEN
            l_next_input := 'TR SN';
        ELSIF mydata = 'ACTION-M-SL'                                  ---查询轨道号
        THEN
            l_next_input := 'MACHINE';
        ELSIF mydata = 'ACTION-M-SC'                           ----錫膏非空瓶下線作業模式
        THEN
            l_next_input := 'TR SN';
        ELSIF mydata = 'ACTION-M-SD'                            ----錫膏空瓶下線作業模式
        THEN
            l_next_input := 'TR SN';
        ELSIF mydata = 'ACTION-M-SE'                            ----錫膏空瓶下線作業模式
        THEN
            l_next_input := 'TR SN';
        ELSIF mydata = 'ACTION-M-P'
        THEN
            l_next_input := 'TR SN';
        ELSIF mydata = 'ACTION-M-SO'                               ---刮刀上線作業模式
        THEN
            IF INSTR (l_ap_station, 'AP') < 1
            THEN
                res := 'SCM-T03659:';
                RAISE l_exit;
            ELSE
                l_next_input := 'TRAVEL SN WO';
            END IF;
        ELSIF mydata = 'ACTION-M-SF'                               ---刮刀下線作業模式
        THEN
            l_next_input := 'SCRAPER SN';
        ELSIF mydata = 'ACTION-M-ST'                               ---钢网上线作业模式
        THEN
            IF INSTR (l_ap_station, 'AP') < 1
            THEN
                res := 'SCM-T03676:';
                RAISE l_exit;
            ELSE
                l_next_input := 'TRAVEL SN WO';
            END IF;
        ELSIF mydata = 'ACTION-M-SN'                               ---钢网下线作业模式
        THEN
            l_next_input := 'STENCIL SN';
        ELSIF mydata = 'ACTION-M-AB'     ---SMT物料預警TO_TEMP By Ryan 20120416---
        THEN
            l_next_input := 'MACHINE';
        ELSIF mydata = 'ACTION-M-AR'           ---SMT物料預警 FROM_TEMP By Ryan---
        THEN
            l_next_input := 'MACHINE';
        ELSIF mydata = 'ACTION-M-AC'          ---SMT物料預警 IPQC_CHECK By Ryan---
        THEN
            -----IPQC人員權限CHECK By Ryan------
            SELECT COUNT (*)
              INTO l_count
              FROM mes1.c_ap_config
             WHERE     emp_no = l_emp
                   AND ap_name = 'SMTCHECK'
                   AND function_name = 'SMT-CHECK';

            IF l_count > 0
            THEN
                l_next_input := 'MACHINE';
            ELSE
                res := 'SCM-T03372';
                RAISE l_exit;
            END IF;
        ---wangyan----add----
        ELSIF SUBSTR (mydata, 1, 11) = 'ACTION-M-FL'
        ------SMT FEEDER 在線鎖定----
        THEN
            SELECT COUNT (*)
              INTO l_count
              FROM mes1.c_ap_config
             WHERE     emp_no = l_emp
                   AND ap_name = 'FEEDERLOCK'
                   AND function_name = 'SMT-CHECK';

            IF l_count > 0
            THEN
                l_next_input := 'SLOT NO';
            ELSE
                res := 'SCM-T03373';
                RAISE l_exit;
            END IF;
        ELSIF mydata = 'ACTION-M-FU'                      ----SMT FEEDER解鎖----
        THEN
            ----IPQC人員權限CHECK By WangYan----
            SELECT COUNT (*)
              INTO l_count
              FROM mes1.c_ap_config
             WHERE     emp_no = l_emp
                   AND ap_name = 'FEEDERUNLOCK'
                   AND function_name = 'SMT-CHECK';

            IF l_count > 0
            THEN
                l_next_input := 'FEEDER NO';
            ELSE
                res := 'SCM-T03374';
                RAISE l_exit;
            END IF;
        ELSIF mydata = 'ACTION-M-FK'
        THEN
            ----SMT FEEDER 在線鎖定----
            SELECT COUNT (*)
              INTO l_count
              FROM mes1.c_ap_config
             WHERE     emp_no = l_emp
                   AND ap_name = 'FEEDERONLINELOCK'
                   AND function_name = 'SMT-CHECK';

            IF l_count > 0
            THEN
                l_next_input := 'ERROR CODE';
            ELSE
                res := 'SCM-T03370';
                RAISE l_exit;
            END IF;
        --超領物料作業代碼
        ELSIF mydata = 'ACTION-M-MO'
        THEN
            l_next_input := 'TRAVEL SN WO';

            DELETE mes4.r_ap_temp2
             WHERE data1 = g_stationno;
        ELSIF mydata = 'ACTION-M-USC' ---SMT update special materila control---
        THEN
            l_next_input := 'TRAVEL SN WO';
        ELSE
            RAISE exp2;
        END IF;

        MES1.INSERT_NEXT_INPUT ('INSERT_NEXT_INPUT',
                                'SCADA-GW28',
                                g_stationno,
                                l_sequence,
                                l_this_input,
                                mydata,
                                l_next_input,
                                '0',
                                '',
                                RES);

        IF RES <> 'OK'
        THEN
            RAISE l_exit;
        END IF;

        COMMIT;
        res := 'OK ACTION CODE';
    --THE ONLY SWITCH,SECOND SECTION...
    ELSE
        --得作業代碼...
        SELECT data5
          INTO l_action_code
          FROM mes4.r_ap_temp
         WHERE     data1 = 'SCADA-GW28'
               AND data2 = g_stationno
               AND data4 = 'ACTION CODE'
               AND ROWNUM = 1;

        --進入判斷...

        ---------------------------------------------------------------
        ------------------ ACTION-M-A用于流程卡切換 -----------------
        ---------------------------------------------------------------
        IF l_action_code = 'ACTION-M-A'
        THEN
            IF l_this_input = 'TRAVEL SN WO'
            THEN
                -- reaper 2025-12-5 检查当前工单对应的机型是否在 AIRI配置表 MES1.c_AIRI_config 中有配置
                -- 已配置且 MES4.r_AIRI_detail 表已配置 工单+机台 返回OK
                -- 已配置且 MES4.r_AIRI_detail 表未配置 工单+机台则配置 返回通知
                MES1.Z_AIRI_CHECKLIST ('ONLINE',
                                       g_stationno,
                                       mydata,
                                       l_ap_station,
                                       l_emp,
                                       '',
                                       '',
                                       '',
                                       '',
                                       RES);

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    l_next_input := 'CHECK EMP';
                    -- reaper 2025-12-5 指定下一步动作是用户确认
                    MES1.INSERT_NEXT_INPUT ('INSERT_NEXT_INPUT',
                                            'SCADA-GW28',
                                            g_stationno,
                                            l_sequence,
                                            l_this_input,
                                            mydata,
                                            l_next_input,
                                            '0',
                                            '',
                                            RES);


                    RAISE l_exit;
                END IF;

                -- reaper 2025-12-5 检查当前工单是否有受控物料
                MES1.Z_AIRI_CHECKLIST ('ONLINE_PROGRAM_CHECK',
                                       g_stationno,
                                       mydata,
                                       l_ap_station,
                                       l_emp,
                                       '',
                                       '',
                                       '',
                                       '',
                                       RES);

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    -- reaper 2025-12-5 指定下一步动作是用户确认
                    l_next_input := 'CHECK_PROGRAM_EMP';

                    INSERT INTO MES4.R_AP_TEMP (DATA1,
                                                DATA2,
                                                DATA3,
                                                DATA4,
                                                DATA5,
                                                DATA6,
                                                DATA7,
                                                WORK_TIME)
                         VALUES ('SCADA-GW28',
                                 G_STATIONNO,
                                 TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                                 l_this_input,
                                 MYDATA,
                                 L_NEXT_INPUT,
                                 '0',
                                 SYSDATE);

                    COMMIT;

                    RAISE l_exit;
                END IF;

                IF INSTR (l_ap_station, 'AP') > 0
                THEN
                    MES1.Z_STATION_KP_CONFIRM_DATA2 ('DATA2ISNULL',
                                                     mydata,
                                                     l_ap_station,
                                                     '',
                                                     RES);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        MES1.Z_STATION_KP_CONFIRM_DATA2 ('CDATA2',
                                                         mydata,
                                                         l_ap_station,
                                                         '',
                                                         RES);
                    END IF;
                END IF;


                MES1.pkg_smt_scan_web_check.check_travelsn_web (mydata,
                                                                l_emp,
                                                                l_ap_station,
                                                                'MACHINE',
                                                                g_stationno,
                                                                '',
                                                                '',
                                                                res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    MES1.Z_STATION_KP_CONFIRM_DATA2 ('INSERTSTATIONKP',
                                                     mydata,
                                                     l_ap_station,
                                                     '',
                                                     RES);

                    DELETE FROM mes4.r_ap_temp
                          WHERE data1 = 'SCADA-GW28' AND data2 = g_stationno;

                    res := 'OK TRAVEL SN WO';
                    COMMIT;
                    --SMT物料預警--------
                    mes1.z_station_shortage_sp ('CHANGE_TRVELSN_NEW',
                                                '',
                                                l_ap_station,
                                                '',
                                                '',
                                                '',
                                                '',
                                                '',
                                                '',
                                                '',
                                                '',
                                                l_emp,
                                                res);

                    IF SUBSTR (res, 1, 2) <> 'OK'
                    THEN
                        res := 'OK';
                    END IF;
                END IF;
            ELSIF l_this_input = 'CHECK EMP'
            THEN
                l_next_input := 'CONFIRM PASSWORD';

                SELECT COUNT (emp_no)
                  INTO i_temp_emp_privilage
                  FROM mes1.c_ap_config
                 WHERE emp_no = mydata AND function_name = 'CHECKEMP_AIRI';

                IF i_temp_emp_privilage > 0
                THEN
                    INSERT INTO MES4.R_AP_TEMP (DATA1,
                                                DATA2,
                                                DATA3,
                                                DATA4,
                                                DATA5,
                                                DATA6,
                                                DATA7,
                                                WORK_TIME)
                         VALUES ('SCADA-GW28',
                                 G_STATIONNO,
                                 TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                                 l_this_input,
                                 MYDATA,
                                 L_NEXT_INPUT,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    RES := 'OK EMP';
                ELSE
                    res := 'SCM-T03198';
                END IF;
            ELSIF l_this_input = 'CONFIRM PASSWORD'
            THEN
                l_next_input := 'TRAVEL SN WO';

                SELECT data5
                  INTO l_ap_emp
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'CHECK EMP'
                       AND ROWNUM = 1;

                SELECT data5
                  INTO l_WO
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'TRAVEL SN WO'
                       AND ROWNUM = 1;

                SELECT COUNT (1)
                  INTO l_count
                  FROM mes1.c_emp
                 WHERE emp_no = l_ap_emp AND EMP_PASSWORD = MYDATA;

                IF l_count > 0
                THEN
                    MES1.Z_AIRI_CHECKLIST ('UNLOCK',
                                           g_stationno,
                                           l_WO,
                                           l_ap_station,
                                           l_ap_emp,
                                           '',
                                           '',
                                           '',
                                           '',
                                           RES);

                    IF SUBSTR (RES, 1, 2) = 'OK'
                    THEN
                        res := 'OK PASSWORD';

                        DELETE MES4.R_AP_TEMP
                         WHERE     DATA2 = g_stationno
                               AND DATA3 >=
                                   (SELECT DATA3
                                      FROM MES4.R_AP_TEMP
                                     WHERE     DATA4 = l_next_input
                                           AND DATA2 = g_stationno
                                           AND ROWNUM = 1)
                               AND DATA7 IS NOT NULL;

                        COMMIT;
                    END IF;
                END IF;
            ELSIF l_this_input = 'CHECK_PROGRAM_EMP'
            THEN
                l_next_input := 'CONFIRM_PROGRAM_PASSWORD';

                SELECT COUNT (emp_no)
                  INTO i_temp_emp_privilage
                  FROM mes1.c_ap_config
                 WHERE emp_no = mydata AND function_name = 'CHECKEMP_PROGRAM';

                IF i_temp_emp_privilage > 0
                THEN
                    INSERT INTO MES4.R_AP_TEMP (DATA1,
                                                DATA2,
                                                DATA3,
                                                DATA4,
                                                DATA5,
                                                DATA6,
                                                DATA7,
                                                WORK_TIME)
                         VALUES ('SCADA-GW28',
                                 G_STATIONNO,
                                 TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                                 l_this_input,
                                 MYDATA,
                                 L_NEXT_INPUT,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    RES := 'OK EMP';
                ELSE
                    res := 'SCM-T03198';
                END IF;
            ELSIF l_this_input = 'CONFIRM_PROGRAM_PASSWORD'
            THEN
                l_next_input := 'TR SN';

                SELECT data5
                  INTO l_ap_emp
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'CHECK_PROGRAM_EMP'
                       AND ROWNUM = 1;

                SELECT COUNT (1)
                  INTO l_count
                  FROM mes1.c_emp
                 WHERE emp_no = l_ap_emp AND EMP_PASSWORD = MYDATA;

                IF l_count > 0
                THEN
                    res := 'OK PASSWORD';

                    INSERT INTO MES4.R_AP_TEMP (DATA1,
                                                DATA2,
                                                DATA3,
                                                DATA4,
                                                DATA5,
                                                DATA6,
                                                DATA7,
                                                WORK_TIME)
                         VALUES ('SCADA-GW28',
                                 G_STATIONNO,
                                 TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                                 l_this_input,
                                 MYDATA,
                                 L_NEXT_INPUT,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                ELSE
                    res := 'SCM-T03085';
                END IF;
            ELSIF l_this_input = 'TR SN'
            THEN
                l_next_input := 'TRAVEL SN WO';

                SELECT data5
                  INTO l_ap_emp
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'CHECK_PROGRAM_EMP'
                       AND ROWNUM = 1;

                SELECT data5
                  INTO l_WO
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'TRAVEL SN WO'
                       AND ROWNUM = 1;


                MES1.Z_AIRI_CHECKLIST ('UNLOCK_PROGRAM_CHECK',
                                       g_stationno,
                                       l_WO,
                                       l_ap_station,
                                       l_ap_emp,
                                       MYDATA,
                                       '',
                                       '',
                                       '',
                                       RES);

                IF SUBSTR (RES, 1, 2) = 'OK'
                THEN
                    res := 'OK TR SN';

                    DELETE MES4.R_AP_TEMP
                     WHERE     DATA2 = g_stationno
                           AND DATA3 >=
                               (SELECT DATA3
                                  FROM MES4.R_AP_TEMP
                                 WHERE     DATA4 = l_next_input
                                       AND DATA2 = g_stationno
                                       AND ROWNUM = 1)
                           AND DATA7 IS NOT NULL;

                    COMMIT;
                END IF;
            END IF;
        ---------------------------------------------------------------
        ------------------ ACTION-AOI用于AOI數據收集-----------------
        ---------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-AOI'
        THEN
            IF l_this_input = 'AOI CONFIG'
            THEN
                BEGIN
                    tmp := mydata;
                    j := 0;
                    k := INSTR (tmp, ';');

                    WHILE k > 0
                    LOOP
                        IF k = 1
                        THEN
                            tmp1 := '-';
                        ELSE
                            tmp1 := TRIM (SUBSTR (tmp, 1, k - 1));
                        END IF;

                        tmp := SUBSTR (tmp, k + 1, LENGTH (tmp) - k);

                        CASE j
                            WHEN 0
                            THEN
                                myprogram := SUBSTR (tmp1, 1, 25);
                            WHEN 1
                            THEN
                                mystation := SUBSTR (tmp1, 1, 25);
                            WHEN 2
                            THEN
                                mytotal := SUBSTR (tmp1, 1, 25);
                            WHEN 3
                            THEN
                                myship := SUBSTR (tmp1, 1, 25);
                            WHEN 4
                            THEN
                                myserial := SUBSTR (tmp1, 1, 25);
                            WHEN 5
                            THEN
                                mylot := SUBSTR (tmp1, 1, 25);
                            WHEN 6
                            THEN
                                mypcb := SUBSTR (tmp1, 1, 25);
                            ELSE
                                res := 'SCM-T03376';
                                RAISE l_exit;
                        END CASE;

                        k := INSTR (tmp, ';');
                        j := j + 1;
                    END LOOP;

                    mypcb := SUBSTR (tmp, 1, 25);            --the rest... ...
                    l_next_input := 'AOI DATA';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time,
                                                data8,
                                                data9,
                                                data10,
                                                data11,
                                                data12,
                                                data13,
                                                data14,
                                                data15)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'AOI CONFIG',
                                 'AOI_Interface',
                                 l_next_input,
                                 '0',
                                 SYSDATE,
                                 myprogram,
                                 mystation,
                                 myinspect,
                                 mytotal,
                                 myship,
                                 myserial,
                                 mylot,
                                 mypcb);

                    --記錄定義﹕
                    --1. DATA8用于記錄AOI程式名﹕T60H937B00R4155A0。。
                    --2. DATA9用于記錄機台名E532AA3。。
                    --3. DATA10用于記錄INSPECT的時間...
                    --4. DATA11用于記錄零件總數1512 ...
                    --5. DATA12用于記錄ship_id.USER---
                    --6. DATA13用于記錄ser_id --
                    --7. DATA14用于記錄lot_id.
                    COMMIT;
                    res := 'OK AOI CONFIG' || tmp;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        RAISE exception_a;
                END;
            ELSIF l_this_input = 'AOI DATA'
            THEN
                ---這個地方應該用于分析所有數據...
                --1. 如果沒有找到AOI_CONFIG﹐則需要做UNDO的動作...
                --2. 要處理PASS和FAIL兩種情況?..
                --需要的數據有﹕
                --1.記錄板子JC977711014H 的號碼
                --2.記錄0;0;1;0;其中//s;u;p;f (skip、untest、pass、fail).
                --.R501_2;R0603;錫少LS;0;0;0;     //CompName;CompType;ConfirmErrCode;0;0;0;.
                --舉例﹕
                --T60H937B00R4155A0;JC977711014N;E532AA3;SHIP;USER;0;20070103;000835;0;0;0;1;T;1512;1;C162_8;C0402;立碑TM;0;0;0;
                OPEN get_aoi_config;

                FETCH get_aoi_config
                    INTO myprogram,
                         mystation,
                         mytotal,
                         myship,
                         myserial,
                         mylot,
                         mypcb;

                CLOSE get_aoi_config;

                tmp := mydata;
                j := 0;
                k := INSTR (tmp, ';');

                WHILE k > 0
                LOOP
                    IF k = 1
                    THEN
                        tmp1 := '';
                    ELSE
                        tmp1 := TRIM (SUBSTR (tmp, 1, k - 1));
                    END IF;

                    tmp := SUBSTR (tmp, k + 1, LENGTH (tmp) - k);

                    CASE j
                        WHEN 1
                        THEN
                            mypanel := tmp1;                               ---
                        WHEN 2
                        THEN
                            myflag := tmp1;                                ---
                        WHEN 0
                        THEN
                            myfilename := tmp1;                            ---
                        WHEN 3
                        THEN
                            myinspect := SUBSTR (tmp1, 1, 25);             ---
                        WHEN 4
                        THEN
                            myship := tmp1;
                        WHEN 5
                        THEN
                            myserial := tmp1;
                        WHEN 6
                        THEN
                            mylot := tmp1;
                        ELSE
                            res := 'SCM-T03377';
                            RAISE l_exit;
                    END CASE;

                    k := INSTR (tmp, ';');
                    j := j + 1;
                END LOOP;

                myinspect := tmp;                             --- the last ...
                ---后處理;
                --第一段﹕如果正常
                res := 'SCM-T03378:' || myfilename;

                IF myflag = 'PASS'
                THEN
                    SELECT COUNT (*)
                      INTO tmp_tmp
                      FROM mes4.r_fb_inspect
                     WHERE file_name = myfilename;

                    IF tmp_tmp = 0
                    THEN
                        INSERT INTO mes4.r_fb_inspect (file_name,
                                                       station_name,
                                                       inspect_time,
                                                       multiboard_no,
                                                       program_name,
                                                       p_sn,
                                                       work_flag,
                                                       comp_qty,
                                                       defect_qty,
                                                       collection_time)
                             VALUES (myfilename,
                                     mystation,
                                     TO_DATE (myinspect, 'YYYYMMDDHH24MISS'),
                                     '1',
                                     myprogram,
                                     mypanel,
                                     '2',
                                     mytotal,
                                     '0',
                                     SYSDATE);

                        COMMIT;
                    END IF;

                    res := 'OK PASS=' || myfilename;
                ELSIF myflag = 'FAIL'
                THEN
                    ----對于多錯誤碼的﹐采用多次分發﹐以數量判定刪除...
                    SELECT COUNT (*)
                      INTO tmp_tmp
                      FROM mes4.r_fb_inspect
                     WHERE file_name = myfilename;

                    IF tmp_tmp = 0
                    THEN
                        INSERT INTO mes4.r_fb_inspect (file_name,
                                                       station_name,
                                                       inspect_time,
                                                       multiboard_no,
                                                       program_name,
                                                       p_sn,
                                                       work_flag,
                                                       comp_qty,
                                                       defect_qty,
                                                       collection_time)
                             VALUES (myfilename,
                                     mystation,
                                     TO_DATE (myinspect, 'YYYYMMDDHH24MISS'),
                                     '1',
                                     myprogram,
                                     mypanel,
                                     '3',
                                     mytotal,
                                     '0',
                                     SYSDATE);

                        COMMIT;
                    END IF;

                    res := 'OK FAIL=' || myfilename;
                ELSIF myflag = 'UNTEST'
                THEN
                    res := 'OK UNTE=' || myfilename;
                ELSIF myflag = 'SKIP'
                THEN
                    res := 'OK SKIP=' || myfilename;
                ELSE
                    res := 'OK UNKN=' || myfilename;
                END IF;
            END IF;
        ---------------------------------------------------------------
        ------------------  ACTION-M-B用于機台上料  -----------------
        ---------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-B'
        THEN
            IF l_this_input = 'MACHINE'
            THEN
                IF l_ap_station <> mydata
                THEN
                    res := 'SCM-T03180';
                    RAISE l_exit;
                END IF;

                MES1.pkg_smt_scan_web_check.CHECK_STATION_MACHINE_WEB (
                    mydata,
                    'MACHINE',
                    l_emp,
                    res);

                --- CHECK BASE INFO... ...
                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    IF INSTR (mydata, 'AP') > 0
                    THEN
                        SELECT NVL (p_no, 0)
                          INTO l_p_no
                          FROM mes4.r_station_wip
                         WHERE station = mydata AND ROWNUM = 1;

                        l_next_station := MES1.check_pno_rout (l_p_no);

                        IF l_next_station = 'AI'
                        THEN
                            --如果第二个工站是AI,不需要扫描钢网
                            L_NEXT_INPUT := 'TR SN';
                        ELSE
                            SELECT COUNT (1)
                              INTO L_COUNT
                              FROM mes4.r_stencil_wip
                             WHERE STATION_NAME = mydata;

                            IF L_COUNT > 0
                            THEN
                                L_NEXT_INPUT := 'TR SN';
                            ELSE
                                res := 'SCM-T03679';
                                RAISE l_exit;
                            END IF;
                        END IF;

                        INSERT INTO MES4.R_AP_TEMP (DATA1,
                                                    DATA2,
                                                    DATA3,
                                                    DATA4,
                                                    DATA5,
                                                    DATA6,
                                                    DATA7,
                                                    WORK_TIME)
                             VALUES ('SCADA-GW28',
                                     G_STATIONNO,
                                     TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                                     'MACHINE',
                                     MYDATA,
                                     L_NEXT_INPUT,
                                     '0',
                                     SYSDATE);

                        COMMIT;
                    ELSIF INSTR (mydata, 'LM') > 0
                    THEN
                        L_NEXT_INPUT := 'TR SN';

                        INSERT INTO MES4.R_AP_TEMP (DATA1,
                                                    DATA2,
                                                    DATA3,
                                                    DATA4,
                                                    DATA5,
                                                    DATA6,
                                                    DATA7,
                                                    WORK_TIME)
                             VALUES ('SCADA-GW28',
                                     G_STATIONNO,
                                     TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                                     'MACHINE',
                                     MYDATA,
                                     L_NEXT_INPUT,
                                     '0',
                                     SYSDATE);
                    ELSE
                        L_NEXT_INPUT := 'SLOT NO';

                        INSERT INTO MES4.R_AP_TEMP (DATA1,
                                                    DATA2,
                                                    DATA3,
                                                    DATA4,
                                                    DATA5,
                                                    DATA6,
                                                    DATA7,
                                                    WORK_TIME)
                             VALUES ('SCADA-GW28',
                                     G_STATIONNO,
                                     TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                                     'MACHINE',
                                     MYDATA,
                                     L_NEXT_INPUT,
                                     '0',
                                     SYSDATE);

                        COMMIT;
                    END IF;
                END IF;
            ELSIF l_this_input = 'STENCIL SN'
            THEN
                SELECT data5
                  INTO l_machine
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'MACHINE'
                       AND ROWNUM = 1;

                SELECT data5
                  INTO l_emp
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'EMP'
                       AND ROWNUM = 1;

                SELECT COUNT (1)
                  INTO L_COUNT
                  FROM MES4.R_STATION_WIP
                 WHERE STATION = L_MACHINE AND ROWNUM = 1;

                IF L_COUNT > 0
                THEN
                    SELECT WO
                      INTO L_WO
                      FROM MES4.R_STATION_WIP
                     WHERE STATION = L_MACHINE AND ROWNUM = 1;
                END IF;

                L_LINE := SUBSTR (l_machine, 1, 5);



                --钢网上线前检查
                MES1.check_stencil ('STENCILCONTROL_ONLINECHECK',
                                    mydata,
                                    '',
                                    '',
                                    l_emp,
                                    L_LINE,
                                    L_MACHINE,
                                    L_WO,
                                    l_emp,
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    USER_CUSOR);

                FETCH USER_CUSOR INTO l_res;

                CLOSE USER_CUSOR;

                res := l_res;

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    res := res;
                    RAISE l_exit;
                END IF;

                --钢网上线
                MES1.check_stencil ('STENCILCONTROL_ONLINE',
                                    mydata,
                                    '',
                                    '',
                                    l_emp,
                                    L_LINE,
                                    L_MACHINE,
                                    L_WO,
                                    l_emp,
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    USER_CUSOR);

                -- check_slotno (mydata, l_machine, res);

                FETCH USER_CUSOR INTO l_res;

                CLOSE USER_CUSOR;

                res := l_res;

                -- check_slotno (mydata, l_machine, res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    l_next_input := 'TR SN';


                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'STENCIL SN',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                ELSE
                    res := res;
                    RAISE l_exit;
                END IF;
            ELSIF l_this_input = 'SLOT NO'
            THEN
                SELECT data5
                  INTO l_machine
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'MACHINE'
                       AND ROWNUM = 1;

                check_slotno (mydata, l_machine, res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    --HET 20180210 lyl
                    --判断是否AI,RI扫描,该扫描情况不需要扫FEEDER NO
                    IF    SUBSTR (l_machine, 4, 1) = 'A'
                       OR SUBSTR (l_machine, 4, 1) = 'R'
                    THEN
                        l_next_input := 'TR SN';
                    ELSE
                        l_next_input := 'FEEDER NO';
                    END IF;

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'SLOT NO',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                ELSE
                    OPEN slot_wip;

                    FETCH slot_wip INTO l_slot_temp;

                    IF slot_wip%NOTFOUND
                    THEN
                        OPEN slot_track_wip;

                        FETCH slot_track_wip INTO l_slot;

                        IF slot_track_wip%FOUND
                        THEN
                            CLOSE slot_track_wip;

                            res := 'SCM-T03118:' || mydata;
                        ELSE
                            CLOSE slot_track_wip;
                        END IF;

                        CLOSE slot_wip;
                    END IF;

                    WHILE slot_wip%FOUND
                    LOOP
                        check_slotno (l_slot_temp, l_machine, res);

                        IF SUBSTR (res, 1, 2) = 'OK'
                        THEN
                            IF    SUBSTR (l_machine, 4, 1) = 'A'
                               OR SUBSTR (l_machine, 4, 1) = 'R'
                            THEN
                                l_next_input := 'TR SN';
                            ELSE
                                l_next_input := 'FEEDER NO';
                            END IF;

                            INSERT INTO mes4.r_ap_temp (data1,
                                                        data2,
                                                        data3,
                                                        data4,
                                                        data5,
                                                        data6,
                                                        data7,
                                                        work_time)
                                     VALUES (
                                                'SCADA-GW28',
                                                g_stationno,
                                                TO_CHAR (
                                                      TO_NUMBER (l_sequence)
                                                    + 1),
                                                'SLOT NO',
                                                l_slot_temp,
                                                l_next_input,
                                                '0',
                                                SYSDATE);

                            COMMIT;
                        END IF;

                        FETCH slot_wip INTO l_slot_temp;
                    END LOOP;

                    CLOSE slot_wip;
                END IF;
            ELSIF l_this_input = 'FEEDER NO'
            THEN
                SELECT data5
                  INTO l_machine
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'MACHINE'
                       AND ROWNUM = 1;

                OPEN wip_track;

                FETCH wip_track INTO l_slot;

                IF wip_track%FOUND
                THEN
                    IF INSTR (mydata, 'TRACK') > 0
                    THEN
                        l_track_tmp :=
                            SUBSTR (mydata, INSTR (mydata, 'TRACK') + 5, 1);

                        IF l_track_tmp = 'L'
                        THEN
                            l_track := '1';
                        ELSIF l_track_tmp = 'M'
                        THEN
                            l_track := '2';
                        ELSIF l_track_tmp = 'R'
                        THEN
                            l_track := '3';
                        END IF;

                        OPEN slot_track;

                        FETCH slot_track INTO l_slot;

                        IF slot_track%NOTFOUND
                        THEN
                            CLOSE slot_track;

                            CLOSE wip_track;

                            res := 'SCM-T03089';
                            RAISE l_exit;
                        END IF;

                        CLOSE slot_track;

                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno
                                    AND data4 = 'SLOT NO'
                                    AND data6 = 'FEEDER NO'
                                    AND data5 NOT LIKE '%-' || l_track || '%';
                    END IF;
                END IF;

                CLOSE wip_track;

                SELECT data5
                  INTO l_slot
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'SLOT NO'
                       AND data6 = 'FEEDER NO'
                       AND ROWNUM = 1;

                ---以下是CHECK FEEDER是否有在線CHANGE--2013-10-07-------BY WANGYAN----
                ----查詢此線的在線的工單，物料---------
                SELECT DISTINCT wo
                  INTO l_wo
                  FROM mes4.r_station_wip
                 WHERE station = l_machine;



                ---以上ADD 2013-10-07---------------------------------------------
                MES1.pkg_smt_scan_web_check.check_feederno_web (
                    UPPER (mydata),
                    l_machine,
                    l_slot,
                    res);

                IF SUBSTR (res, 1, 2) = 'OK' --+以下一句為﹕PCH﹕2006-08-12-ADD--+------------------
                                             OR SUBSTR (res, 1, 6) = 'NOTICE'
                --+以上一句為﹕PCH﹕2006-08-12-ADD--+------------------
                THEN
                    l_next_input := 'TR SN';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'FEEDER NO',
                                 UPPER (mydata),
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                --RES:='OK FEEDER NO';
                END IF;
            ELSIF l_this_input = 'TR SN'
            THEN
                res := 'SCM-T03379:' || mydata;
                --2025-12-2 获取条码的TRSN
                SELECT mes1.GET_SCAN_SN_ALLPART (mydata)
                  INTO g_tr_sn
                  FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    --仓库没发料
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                --检查条码是否是合法条码
                SELECT COUNT (1)
                  INTO l_count
                  FROM mes4.r_tr_sn
                 WHERE tr_sn = g_tr_sn;

                IF l_count < 1
                THEN
                    res := 'SCM-T03444:' || mydata;
                    RAISE l_exit;
                END IF;

                /**
                 * 2025-6-12 新增上料前检查是否兰吉尔物料,兰吉尔物料卡控S开头的条码
                 */
                select COUNT (1) INTO l_count from mes4.customer_materials m where m.material=(select r.cust_kp_no from mes4.r_2d_sn_relation r where r.barcode_2d=mydata);

                IF l_count > 0
                THEN
                    IF substr(upper(mydata),1,1) <> 'S'
                    THEN
                        res := 'SCM-T03708:' || mydata ; --'兰吉尔物料上料必须是S开头的条码';
                        RAISE l_exit;
                    END IF;

                    select count(1) into l_count from mes4.customer_sns s where s.sn=mydata;
                    IF l_count < 1 THEN
                        res := '当前上料条码不是兰吉尔物料条码1'; --'兰吉尔物料上料必须是S开头的条码';
                        RAISE l_exit;
                    end if;

                end if;

                res := 'SCM-T03391:' || g_stationno;

                SELECT data5
                  INTO l_machine
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'MACHINE'
                       AND ROWNUM = 1;

                res := 'SCM-T03392:' || g_stationno;

                --获取工单信息
                SELECT COUNT (1)
                  INTO L_COUNT
                  FROM mes4.r_station_wip
                 WHERE station = l_machine;

                IF l_count > 0
                THEN
                    SELECT wo, PROCESS_FLAG
                      INTO l_wo, l_process_flag
                      FROM mes4.r_station_wip
                     WHERE station = l_machine AND ROWNUM = 1;
                ELSE
                    res := 'SCM-T03393:';
                    RAISE l_exit;
                END IF;

                IF INSTR (l_machine, 'AP') > 0
                THEN
                    SELECT COUNT (1)
                      INTO L_COUNT
                      FROM mes4.C_SOLDERPASTE_BASE
                     WHERE KP_NO = (SELECT cust_kp_no
                                      FROM mes4.r_tr_sn
                                     WHERE tr_sn = g_tr_sn);

                    IF L_COUNT > 0
                    THEN
                        --是锡膏料号，检查钢网,刮刀配套使用的锡膏是否更换
                        res :=
                            MES1.CHECK_STEANDFIX_KPMGR (
                                p_type      => 5,
                                p_trsn      => g_tr_sn,
                                p_station   => l_machine,
                                p_wo        => l_wo,
                                p_line =>'');

                        IF SUBSTR (res, 1, 2) <> 'OK'
                        THEN
                            RAISE l_exit;
                        END IF;
                    END IF;


                    IF L_COUNT > 0
                    THEN
                        --检查物料超时（自动根据物料状态判断），返回不是OK，则存在超时
                        --调用示例：
                        mes1.pkg_solder_base.FEEDING_CHECK (g_tr_sn,
                                                            'CN',
                                                            res);

                        IF SUBSTR (res, 1, 2) <> 'OK'
                        THEN
                            RAISE l_exit;
                        END IF;

                        --锡膏，检查锡膏是否发料是否走锡膏流程 and check solder times control
                        MES1.CHECK_DATA_PUBLIC (RES,
                                                'SOLDER_CHECKOUT_WO',
                                                g_tr_sn,
                                                l_wo,
                                                l_machine,
                                                '',
                                                '',
                                                '',
                                                '',
                                                '');

                        IF SUBSTR (res, 1, 2) <> 'OK'
                        THEN
                            RAISE l_exit;
                        END IF;
                    END IF;

                    --检查上钢网和上料的工单是否一致
                    SELECT COUNT (1)
                      INTO L_COUNT
                      FROM MES4.R_STENCIL_WIP RSW, MES4.R_STATION_WIP RSNW
                     WHERE     RSW.WO = RSNW.WO
                           AND RSW.STATION_NAME = RSNW.STATION
                           AND RSW.STATION_NAME = l_machine;

                    IF L_COUNT > 0
                    THEN
                        SELECT STENCIL_SN
                          INTO l_feeder
                          FROM MES4.R_STENCIL_WIP
                         WHERE STATION_NAME = l_machine;
                    ELSE
                        res := 'SCM-T03594:' || l_machine || ',' || l_wo;
                        RAISE l_exit;
                    END IF;
                ELSIF INSTR (l_machine, 'LM') > 0
                THEN
                    l_feeder := 'N/A';
                    l_slot := 'N/A';
                ELSE
                    IF    SUBSTR (l_machine, 4, 1) = 'A'
                       OR SUBSTR (l_machine, 4, 1) = 'R'
                    THEN
                        SELECT data5
                          INTO l_slot
                          FROM mes4.r_ap_temp
                         WHERE     data1 = 'SCADA-GW28'
                               AND data2 = g_stationno
                               AND data4 = 'SLOT NO'
                               AND data6 = 'TR SN'
                               AND ROWNUM = 1;
                    ELSE
                        SELECT data5
                          INTO l_slot
                          FROM mes4.r_ap_temp
                         WHERE     data1 = 'SCADA-GW28'
                               AND data2 = g_stationno
                               AND data4 = 'SLOT NO'
                               AND data6 = 'FEEDER NO'
                               AND ROWNUM = 1;
                    END IF;


                    res := 'SCM-T03430:' || g_stationno;

                    ---需要做调整  FOR AI ,RI
                    IF    SUBSTR (l_machine, 4, 1) = 'A'
                       OR SUBSTR (l_machine, 4, 1) = 'R'
                       OR SUBSTR (l_machine, 4, 1) = 'L'
                    THEN
                        l_feeder := 'N/A';
                    ELSE
                        SELECT data5
                          INTO l_feeder
                          FROM mes4.r_ap_temp
                         WHERE     data1 = 'SCADA-GW28'
                               AND data2 = g_stationno
                               AND data4 = 'FEEDER NO'
                               AND ROWNUM = 1;
                    END IF;
                END IF;


                --check specilal control start add by Tommis 20210714
                --2025-12-2检查工单中的特殊料号管控
                MES1.CHECK_DATA_PUBLIC (RES,
                                        'SPECIALRULE_PROGRAM_CHECK',
                                        g_tr_sn,
                                        l_wo,
                                        l_machine,
                                        '',
                                        l_slot,
                                        l_process_flag,
                                        '',
                                        '');

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    RAISE l_exit;
                END IF;

                --check specilal control end add by Tommis 20210714

                --检查Bincode信息Start
                res := 'SCM-T03394:' || g_tr_sn;
                mes1.check_material_mfr_change (res,
                                                'SMT_BINCODE_CONTROL_LINE',
                                                g_tr_sn,
                                                l_slot,
                                                g_stationno);

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    RAISE l_exit;
                END IF;

                --检查Bincode信息End


                -- begin MFR change check logic --
                --獲取參數，看物料變化是否需要CHECK EMP --
                res := 'SCM-T03395:' || mydata;

                OPEN get_check_emp_value;

                FETCH get_check_emp_value
                    INTO tmp_check_emp_value, tmp_check_mfr_emp;

                IF get_check_emp_value%FOUND
                THEN
                    -- 2025-12-2 生产机配置的就是N&Y
                    IF tmp_check_emp_value = 'N' AND tmp_check_mfr_emp = 'Y'
                    THEN
                        --参数配置,确认是否需要检查厂商变化 ,CHECK MFR Change--
                        --多一槍CHECK EMP 時，先檢查TR_SN狀態--
                        res := 'SCM-T03396:' || g_tr_sn;
                        MES1.pkg_smt_scan_web_check.check_trsn_on_kp_temp_web (
                            g_tr_sn,
                            l_emp,
                            l_machine,
                            l_slot,
                            l_feeder,
                            'MACHINE',
                            g_stationno,
                            res);

                        IF SUBSTR (res, 1, 2) <> 'OK'
                        THEN
                            RAISE l_exit;
                        END IF;

                        --检查上料厂商是否有变更的情况--
                        res := 'SCM-T03394:' || g_tr_sn;
                        mes1.check_material_mfr_change (
                            res,
                            'SMT_ACTION_B_CHECKEMP',
                            g_tr_sn,
                            l_slot,
                            l_machine);

                        IF SUBSTR (res, 1, 9) = 'DIFFERENT'
                        THEN
                            --有变更,需要输入有权限的工号进行确认
                            l_next_input := 'CHECK EMP';

                            INSERT INTO mes4.r_ap_temp (data1,
                                                        data2,
                                                        data3,
                                                        data4,
                                                        data5,
                                                        data6,
                                                        data7,
                                                        work_time)
                                     VALUES (
                                                'SCADA-GW28',
                                                g_stationno,
                                                TO_CHAR (
                                                      TO_NUMBER (l_sequence)
                                                    + 1),
                                                'TR SN',
                                                g_tr_sn,
                                                l_next_input,
                                                '0',
                                                SYSDATE);

                            COMMIT;
                            res := 'OK,' || res;
                        ELSE
                            --没有厂商变更的情况,正常上料.CHECK OK ,則PASS，使用原始功能 --
                            res := 'SCM-T03381:' || g_tr_sn;
                            MES1.pkg_smt_scan_web_check_lyl.CHECK_TRSN_ON_KP_WEB (
                                g_tr_sn,
                                l_emp,
                                l_machine,
                                l_slot,
                                l_feeder,
                                'MACHINE',
                                res);

                            IF SUBSTR (res, 1, 2) = 'OK'
                            THEN
                                IF     INSTR (l_machine, 'AP') < 1
                                   AND INSTR (l_machine, 'LM') < 1
                                THEN
                                    DELETE FROM
                                        mes4.r_ap_temp
                                          WHERE     data1 = 'SCADA-GW28'
                                                AND data2 = g_stationno
                                                AND data4 IN
                                                        ('SLOT NO',
                                                         'FEEDER NO');

                                    COMMIT;

                                    UPDATE mes4.r_ap_temp
                                       SET data6 = 'SLOT NO/END'
                                     WHERE     data1 = 'SCADA-GW28'
                                           AND data2 = g_stationno
                                           AND data4 = 'MACHINE';

                                    ----SMT 物料預警-----
                                    res := 'SCM-T03382:' || g_tr_sn;
                                    mes1.z_station_shortage_sp (
                                        'CHANGE_MATERIAL',
                                        '',
                                        l_ap_station,
                                        l_slot,
                                        '',
                                        g_tr_sn,
                                        '',
                                        '',
                                        '',
                                        '',
                                        '',
                                        l_emp,
                                        res);

                                    IF SUBSTR (res, 1, 2) <> 'OK'
                                    THEN
                                        res := 'OK';
                                    END IF;
                                --印刷机预警时要调CHANGE_MATERIAL_DIP，因为印刷机没有轨道号，印刷机的物料也是配在MES1.C_STATION_KP中；
                                ELSE
                                    res := 'SCM-T03382:' || g_tr_sn;
                                    mes1.z_station_shortage_sp (
                                        'CHANGE_MATERIAL_DIP',
                                        '',
                                        l_ap_station,
                                        l_slot,
                                        '',
                                        g_tr_sn,
                                        '',
                                        '',
                                        '',
                                        '',
                                        '',
                                        l_emp,
                                        res);

                                    IF SUBSTR (res, 1, 2) <> 'OK'
                                    THEN
                                        res := 'OK';
                                    END IF;
                                END IF;
                            --RES:='OK TR SN';
                            END IF;
                        END IF;
                    ELSE
                        --參數有配置，但此CHECK 為N，使用原始功能--
                        ---原始代碼--
                        res := 'SCM-T03381:' || g_tr_sn;
                        MES1.pkg_smt_scan_web_check_lyl.CHECK_TRSN_ON_KP_WEB (
                            g_tr_sn,
                            l_emp,
                            l_machine,
                            l_slot,
                            l_feeder,
                            'MACHINE',
                            res);

                        IF SUBSTR (res, 1, 2) = 'OK'
                        THEN
                            IF INSTR (l_machine, 'AP') < 1
                            THEN
                                DELETE FROM
                                    mes4.r_ap_temp
                                      WHERE     data1 = 'SCADA-GW28'
                                            AND data2 = g_stationno
                                            AND data4 IN
                                                    ('SLOT NO', 'FEEDER NO');

                                COMMIT;

                                UPDATE mes4.r_ap_temp
                                   SET data6 = 'SLOT NO/END'
                                 WHERE     data1 = 'SCADA-GW28'
                                       AND data2 = g_stationno
                                       AND data4 = 'MACHINE';

                                ---SMT 物料預警-----
                                res := 'SCM-T03382:' || g_tr_sn;

                                mes1.z_station_shortage_sp (
                                    'CHANGE_MATERIAL',
                                    '',
                                    l_ap_station,
                                    l_slot,
                                    '',
                                    g_tr_sn,
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    l_emp,
                                    res);

                                IF SUBSTR (res, 1, 2) <> 'OK'
                                THEN
                                    res := 'OK';
                                END IF;
                            --印刷机预警时要调CHANGE_MATERIAL_DIP，因为印刷机没有轨道号，印刷机的物料也是配在MES1.C_STATION_KP中；
                            ELSE
                                res := 'SCM-T03382:' || g_tr_sn;
                                mes1.z_station_shortage_sp (
                                    'CHANGE_MATERIAL_DIP',
                                    '',
                                    l_ap_station,
                                    l_slot,
                                    '',
                                    g_tr_sn,
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    l_emp,
                                    res);

                                IF SUBSTR (res, 1, 2) <> 'OK'
                                THEN
                                    res := 'OK';
                                END IF;
                            END IF;
                        --RES:='OK TR SN';
                        END IF;
                    END IF;
                ELSE
                    --參數沒有配置，原始模塊--
                    res := 'SCM-T03381:' || g_tr_sn;
                    MES1.pkg_smt_scan_web_check.CHECK_TRSN_ON_KP_WEB (
                        g_tr_sn,
                        l_emp,
                        l_machine,
                        l_slot,
                        l_feeder,
                        'MACHINE',
                        res);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno
                                    AND data4 IN ('SLOT NO', 'FEEDER NO');

                        COMMIT;

                        UPDATE mes4.r_ap_temp
                           SET data6 = 'SLOT NO/END'
                         WHERE     data1 = 'SCADA-GW28'
                               AND data2 = g_stationno
                               AND data4 = 'MACHINE';

                        res := 'SCM-T03382:' || g_tr_sn;

                        IF INSTR (l_machine, 'AP') < 1
                        THEN
                            mes1.z_station_shortage_sp ('CHANGE_MATERIAL',
                                                        '',
                                                        l_ap_station,
                                                        l_slot,
                                                        '',
                                                        g_tr_sn,
                                                        '',
                                                        '',
                                                        '',
                                                        '',
                                                        '',
                                                        l_emp,
                                                        res);
                        ELSE
                            mes1.z_station_shortage_sp (
                                'CHANGE_MATERIAL_DIP',
                                '',
                                l_ap_station,
                                l_slot,
                                '',
                                g_tr_sn,
                                '',
                                '',
                                '',
                                '',
                                '',
                                l_emp,
                                res);
                        END IF;

                        IF SUBSTR (res, 1, 2) <> 'OK'
                        THEN
                            res := 'OK';
                        END IF;
                    --RES:='OK TR SN';
                    END IF;
                END IF;

                CLOSE get_check_emp_value;

                IF INSTR (l_machine, 'AP') > 0
                THEN
                  SELECT COUNT (1)
                      INTO L_COUNT
                      FROM mes4.C_SOLDERPASTE_BASE
                     WHERE KP_NO = (SELECT cust_kp_no
                                      FROM mes4.r_tr_sn
                                     WHERE tr_sn = g_tr_sn);

                    IF L_COUNT > 0
                    THEN
                        --是锡膏料号，检查钢网,刮刀配套使用的锡膏是否更换
                        res :=
                            MES1.CHECK_STEANDFIX_KPMGR (
                                p_type      => 3,
                                p_trsn      => g_tr_sn,
                                p_station   => l_machine,
                                p_wo        => l_wo,
                                p_line =>'');

                        IF SUBSTR (res, 1, 2) <> 'OK'
                        THEN
                            RAISE l_exit;
                        END IF;
                    END IF;
                END IF;
            -- End MFR change check logic by andy 20100922--


            ELSIF l_this_input = 'CHECK EMP'
            THEN
                --增加CHECK EMP by andy 20100922--
                SELECT data5
                  INTO l_machine
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'MACHINE'
                       AND ROWNUM = 1;

                SELECT data5
                  INTO l_slot
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'SLOT NO'
                       AND data6 = 'FEEDER NO'
                       AND ROWNUM = 1;

                SELECT data5
                  INTO l_feeder
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'FEEDER NO'
                       AND ROWNUM = 1;

                SELECT data5
                  INTO l_temp_new_trsn
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'TR SN'
                       AND data6 = 'CHECK EMP'
                       AND ROWNUM = 1;

                --检查用户是否合法
                AP.PKG_COMMON_FUNCTIONS.CHECK_MES_USER_EXIST (mydata, res);

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    RAISE l_exit;
                END IF;

                --检查用户是否有权限
                SELECT COUNT (emp_no)
                  INTO i_temp_emp_privilage
                  FROM mes1.c_ap_config
                 WHERE emp_no = mydata AND function_name = 'CHECKEMP';

                IF i_temp_emp_privilage > 0
                THEN
                    res := 'SCM-T03394:' || mydata;
                    mes1.check_material_mfr_change (res,
                                                    'LOG_ME_UNLOCK_ACTION_B',
                                                    l_temp_new_trsn,
                                                    mydata,
                                                    l_machine);

                    IF SUBSTR (res, 1, 2) <> 'OK'
                    THEN
                        RAISE l_exit;
                    END IF;

                    l_next_input := 'CONFIRM PASSWORD';
                    MES1.INSERT_NEXT_INPUT ('INSERT_NEXT_INPUT',
                                            'SCADA-GW28',
                                            g_stationno,
                                            l_sequence,
                                            l_this_input,
                                            mydata,
                                            l_next_input,
                                            '0',
                                            '',
                                            RES);

                    --记录解锁人员
                    INSERT INTO MES4.R_SMT_UNLOCK_LOG (STATION,
                                                       SLOT_NO,
                                                       KP_NO,
                                                       EMP_NO)
                         VALUES (L_MACHINE,
                                 L_SLOT,
                                 L_TEMP_NEW_TRSN,
                                 MYDATA);

                    COMMIT;
                ELSE
                    res := 'SCM-T03309';
                    RAISE l_exit;
                END IF;
            ELSIF l_this_input = 'SLOT NO/END'
            THEN
                SELECT data5
                  INTO l_machine
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'MACHINE'
                       AND ROWNUM = 1;

                check_slotno (mydata, l_machine, res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    IF    SUBSTR (l_machine, 4, 1) = 'A'
                       OR SUBSTR (l_machine, 4, 1) = 'R'
                    THEN
                        l_next_input := 'TR SN';
                    ELSE
                        l_next_input := 'FEEDER NO';
                    END IF;

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'SLOT NO',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                ELSE
                    OPEN slot_wip;

                    FETCH slot_wip INTO l_slot_temp;

                    IF slot_wip%FOUND
                    THEN
                        WHILE slot_wip%FOUND
                        LOOP
                            check_slotno (l_slot_temp, l_machine, res);

                            IF SUBSTR (res, 1, 2) = 'OK'
                            THEN
                                IF    SUBSTR (l_machine, 4, 1) = 'A'
                                   OR SUBSTR (l_machine, 4, 1) = 'R'
                                THEN
                                    l_next_input := 'TR SN';
                                ELSE
                                    l_next_input := 'FEEDER NO';
                                END IF;

                                INSERT INTO mes4.r_ap_temp (data1,
                                                            data2,
                                                            data3,
                                                            data4,
                                                            data5,
                                                            data6,
                                                            data7,
                                                            work_time)
                                         VALUES (
                                                    'SCADA-GW28',
                                                    g_stationno,
                                                    TO_CHAR (
                                                          TO_NUMBER (
                                                              l_sequence)
                                                        + 1),
                                                    'SLOT NO',
                                                    l_slot_temp,
                                                    l_next_input,
                                                    '0',
                                                    SYSDATE);

                                COMMIT;
                            END IF;

                            FETCH slot_wip INTO l_slot_temp;
                        END LOOP;

                        CLOSE slot_wip;
                    ELSE
                        OPEN slot_track_wip;

                        FETCH slot_track_wip INTO l_slot;

                        IF slot_track_wip%FOUND
                        THEN
                            CLOSE slot_track_wip;

                            res := 'SLOT ALREADY FULL/' || mydata;
                        ELSE
                            CLOSE slot_track_wip;
                        END IF;

                        CLOSE slot_wip;
                    END IF;            -------------------ADD BY LFL 2004/4/21
                END IF;

                IF mydata = 'END'
                THEN
                    check_end (mydata,
                               l_machine,
                               l_emp,
                               res);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno;

                        COMMIT;
                    ELSIF SUBSTR (res, 1, 17) = 'SLOT NOT FINISHED'
                    THEN
                        l_next_input := 'SHORTAGE CONFIRM/SLOT NO';

                        INSERT INTO mes4.r_ap_temp (data1,
                                                    data2,
                                                    data3,
                                                    data4,
                                                    data5,
                                                    data6,
                                                    data7,
                                                    work_time)
                             VALUES ('SCADA-GW28',
                                     g_stationno,
                                     TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                     'SLOT NO',
                                     mydata,
                                     l_next_input,
                                     '0',
                                     SYSDATE);

                        COMMIT;
                    END IF;
                END IF;
            ELSIF l_this_input = 'SHORTAGE CONFIRM/SLOT NO'
            THEN
                IF mydata = 'CONFIRM-S'
                THEN
                    l_next_input := 'CONFIRM PASSWORD';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'SHORTAGE CONFIRM',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK CONFIRM CODE';
                ELSE
                    SELECT data5
                      INTO l_machine
                      FROM mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data4 = 'MACHINE'
                           AND ROWNUM = 1;

                    check_slotno (mydata, l_machine, res);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        IF    SUBSTR (l_machine, 4, 1) = 'A'
                           OR SUBSTR (l_machine, 4, 1) = 'R'
                        THEN
                            l_next_input := 'TR SN';
                        ELSE
                            l_next_input := 'FEEDER NO';
                        END IF;

                        INSERT INTO mes4.r_ap_temp (data1,
                                                    data2,
                                                    data3,
                                                    data4,
                                                    data5,
                                                    data6,
                                                    data7,
                                                    work_time)
                             VALUES ('SCADA-GW28',
                                     g_stationno,
                                     TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                     'SLOT NO',
                                     mydata,
                                     l_next_input,
                                     '0',
                                     SYSDATE);

                        COMMIT;
                    ELSE               -------------------ADD BY LFL 2004/4/21
                        OPEN slot_wip;

                        FETCH slot_wip INTO l_slot_temp;

                        IF slot_wip%FOUND
                        THEN
                            WHILE slot_wip%FOUND
                            LOOP
                                check_slotno (l_slot_temp, l_machine, res);

                                IF SUBSTR (res, 1, 2) = 'OK'
                                THEN
                                    IF    SUBSTR (l_machine, 4, 1) = 'A'
                                       OR SUBSTR (l_machine, 4, 1) = 'R'
                                    THEN
                                        l_next_input := 'TR SN';
                                    ELSE
                                        l_next_input := 'FEEDER NO';
                                    END IF;

                                    INSERT INTO mes4.r_ap_temp (data1,
                                                                data2,
                                                                data3,
                                                                data4,
                                                                data5,
                                                                data6,
                                                                data7,
                                                                work_time)
                                             VALUES (
                                                        'SCADA-GW28',
                                                        g_stationno,
                                                        TO_CHAR (
                                                              TO_NUMBER (
                                                                  l_sequence)
                                                            + 1),
                                                        'SLOT NO',
                                                        l_slot_temp,
                                                        l_next_input,
                                                        '0',
                                                        SYSDATE);

                                    COMMIT;
                                END IF;

                                FETCH slot_wip INTO l_slot_temp;
                            END LOOP;

                            CLOSE slot_wip;
                        ELSE
                            OPEN slot_track_wip;

                            FETCH slot_track_wip INTO l_slot;

                            IF slot_track_wip%FOUND
                            THEN
                                CLOSE slot_track_wip;

                                res := 'SCM-T03118:' || mydata;
                            ELSE
                                CLOSE slot_track_wip;
                            END IF;

                            CLOSE slot_wip;
                        END IF;
                    END IF;
                END IF;
            ELSIF l_this_input = 'CONFIRM PASSWORD'
            THEN
                l_emp :=
                    MES1.GETALL_INPUT_DATA ('EMP',
                                            g_stationno,
                                            '',
                                            '',
                                            '');


                  L_CHECK_emp :=   MES1.GETALL_INPUT_DATA ('CHECK EMP',
                                            g_stationno,
                                            '',
                                            '',
                                            '') ;
                l_machine :=
                    MES1.GETALL_INPUT_DATA ('MACHINE',
                                            g_stationno,
                                            '',
                                            '',
                                            '');
                l_slot :=
                    MES1.GETALL_INPUT_DATA ('SLOT NO',
                                            g_stationno,
                                            'FEEDER NO',
                                            '',
                                            '');
                l_feeder :=
                    MES1.GETALL_INPUT_DATA ('FEEDER NO',
                                            g_stationno,
                                            '',
                                            '',
                                            '');
                l_temp_new_trsn :=
                    MES1.GETALL_INPUT_DATA ('TR SN',
                                            g_stationno,
                                            'CHECK EMP',
                                            '',
                                            '');



                CHECK_PASSWORD_ONLIN (mydata,
                                      L_CHECK_emp,
                                      l_machine,
                                      res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    MES1.Z_EXCUT_ONLINE_PASS (l_temp_new_trsn,
                                              l_emp,L_CHECK_emp,
                                              l_machine,
                                              l_slot,
                                              l_feeder,
                                              g_stationno,
                                              RES);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno;
                    ELSE
                        RAISE l_exit;
                    END IF;
                END IF;
            ELSE
                res := 'SCM-T03082';
            END IF;
        ---------------------------------------------------------------
        ------------------  ACTION-M-C用于非空盤下料 -----------------
        ---------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-C'
        THEN
            IF l_this_input = 'TR SN'
            THEN
                res := 'SCM-T03379:' || mydata;

                SELECT mes1.get_scan_sn (mydata) INTO g_tr_sn FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    --res := '料盘序号不存在 3,仓库未发料' || mydata;
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                res := 'SCM-T03276';

                SELECT COUNT (1)
                  INTO l_count1
                  FROM mes4.r_station_wip
                 WHERE tr_sn = g_tr_sn;

                IF l_count1 = 0
                THEN
                    res := 'SCM-T03416';
                    RAISE l_exit;
                END IF;

                res := 'SCM-T03278';

                SELECT station
                  INTO l_machine1
                  FROM mes4.r_station_wip
                 WHERE tr_sn = g_tr_sn AND ROWNUM = 1;

                notnull_offkp_trsn (g_tr_sn,
                                    'MACHINE',
                                    l_emp,
                                    res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    UPDATE mes4.r_ap_temp
                       SET data6 = 'TR SN/END'
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data4 = 'ACTION CODE';

                    COMMIT;
                END IF;

                MES1.pkg_smt_scan_web_check.CHECK_STATION_MACHINE_WEB (
                    l_machine1,
                    'MACHINE',
                    l_emp,
                    res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    res := 'OK TR SN';
                END IF;
            ELSIF l_this_input = 'TR SN/END'
            THEN
                res := 'SCM-T03379:' || mydata;

                SELECT mes1.get_scan_sn (mydata) INTO g_tr_sn FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    --res := '料盘序号不存在 3-1,仓库未发料' || mydata;
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                res := 'call notnull_offkp_trsn error,' || mydata;
                notnull_offkp_trsn (g_tr_sn,
                                    'MACHINE',
                                    l_emp,
                                    res);

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    IF mydata = 'END'
                    THEN
                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno;

                        COMMIT;
                        res := 'OK END';
                    ELSE
                        res := 'ERROR TR SN';
                    END IF;
                END IF;
            END IF;
        ---------------------------------------------------------------
        ------------------  ACTION-M-D用于空盤下料 -----------------
        ---------------------------------------------------------------
        ELSIF l_action_code = '~ACTION-M-D'
        THEN
            IF l_this_input = 'CONFIRM CODE'
            THEN
                IF mydata = 'CONFIRM-S'
                THEN
                    l_next_input := 'TR SN';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'CONFIRM CODE',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK CONFIRM CODE';
                ELSE
                    res := 'SCM-T03084';
                END IF;
            ELSIF l_this_input = 'TR SN'
            THEN
                res := 'SCM-T03379:' || mydata;

                SELECT mes1.get_scan_sn (mydata) INTO g_tr_sn FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    --res := '料盘序号不存在 4,仓库未发料' || mydata;
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                res := 'SCM-T03278';

                SELECT station
                  INTO l_machine1
                  FROM mes4.r_station_wip
                 WHERE tr_sn = g_tr_sn AND ROWNUM = 1;

                null_offkp_trsn (g_tr_sn,
                                 'MACHINE',
                                 l_emp,
                                 res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    UPDATE mes4.r_ap_temp
                       SET data6 = 'TR SN/END'
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data4 = 'CONFIRM CODE';

                    COMMIT;
                END IF;

                MES1.pkg_smt_scan_web_check.CHECK_STATION_MACHINE_WEB (
                    l_machine1,
                    'MACHINE',
                    l_emp,
                    res);
            ELSIF l_this_input = 'TR SN/END'
            THEN
                res := 'SCM-T03379:' || mydata;

                SELECT mes1.get_scan_sn (mydata) INTO g_tr_sn FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    --res := '料盘序号不存在 4-1,仓库未发料' || mydata;
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                res := 'SCM-T03431:' || mydata;
                null_offkp_trsn (g_tr_sn,
                                 'MACHINE',
                                 l_emp,
                                 res);

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    IF mydata = 'END'
                    THEN
                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno;

                        COMMIT;
                        res := 'OK END';
                    ELSE
                        res := 'ERROR TR SN';
                    END IF;
                END IF;
            END IF;
        ---------------------------------------------------------------
        ------------------ ACTION-M-E用于整機台下料 -----------------
        ---------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-E'
        THEN
            IF l_this_input = 'CONFIRM CODE'
            THEN
                IF mydata = 'CONFIRM-S'
                THEN
                    l_next_input := 'MACHINE';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'CONFIRM CODE',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK CONFIRM CODE';
                ELSE
                    res := 'ERROR CONFIRM CODE';
                END IF;
            ELSIF l_this_input = 'MACHINE'
            THEN
                IF l_ap_station <> mydata
                THEN
                    res := 'MACHINE ERROR';
                    RAISE l_exit;
                END IF;

                offkp_machine_station (mydata,
                                       'MACHINE',
                                       l_emp,
                                       res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    DELETE FROM mes4.r_ap_temp
                          WHERE data1 = 'SCADA-GW28' AND data2 = g_stationno;

                    COMMIT;
                END IF;
            ELSE
                res := 'SYSTEM ERROR';
            END IF;
        ---------------------------------------------------------------
        ------------------ ACTION-M-H用于機台換料  -----------------
        ---------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-H'
        THEN
            IF l_this_input = 'SLOT NO'
            THEN
                SELECT COUNT (*)
                  INTO l_count
                  FROM mes4.r_station_wip
                 WHERE station = l_ap_station AND slot_no = mydata;
                 --轨道号在线, 下一步扫条码
                IF l_count > 0
                THEN
                    l_next_input := 'OLD TR SN';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'SLOT NO',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    res := 'OK SLOT NO';
                    COMMIT;
                ELSE
                    res := 'SCM-T03380';
                END IF;
            ELSIF l_this_input = 'OLD TR SN'
            THEN
                res := 'SCM-T03379:' || mydata;

                SELECT mes1.GET_SCAN_SN_ALLPART (mydata)
                  INTO g_tr_sn
                  FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                --检查条码是否是合法条码
                SELECT COUNT (1)
                  INTO l_count
                  FROM mes4.r_tr_sn
                 WHERE tr_sn = g_tr_sn;

                IF l_count < 1
                THEN
                    res := 'SCM-T03444:' || mydata;
                    RAISE l_exit;
                END IF;

                res := 'SCM-T03257';
                --tmp_check_slot是否检查轨道,生产机配置为Y  /  l_is_apmachine 是否为AP或LM
                IF tmp_check_slot = 'Y' AND NVL (l_is_apmachine, 'NA') <> 'Y'
                THEN
                    SELECT data5
                      INTO l_slot
                      FROM mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data4 = 'SLOT NO'
                           AND ROWNUM = 1;

                    SELECT COUNT (1)
                      INTO l_count
                      FROM mes4.r_tr_sn a, mes4.r_station_wip b
                     WHERE     b.kp_no = a.cust_kp_no
                           AND b.tr_sn = a.tr_sn
                           AND b.station = l_ap_station
                           AND b.slot_no = l_slot
                           AND b.tr_sn = g_tr_sn;

                    IF l_count = 0
                    THEN
                        --旧条码与轨道号不匹配
                        res := 'SCM-T03667:' || g_tr_sn || ',' || l_slot;
                        RAISE l_exit;
                    END IF;
                ELSIF     tmp_check_slot = 'Y'
                      AND NVL (l_is_apmachine, 'NA') = 'Y'
                THEN
                    SELECT COUNT (1)
                      INTO l_count
                      FROM mes4.r_tr_sn a, mes4.r_station_wip b
                     WHERE     b.kp_no = a.cust_kp_no
                           AND a.tr_sn = b.tr_sn
                           AND b.station = l_ap_station
                           AND a.tr_sn = g_tr_sn;

                    IF l_count = 0
                    THEN
                        res := 'SCM-T03308:' || l_slot;
                        RAISE l_exit;
                    END IF;
                ELSE
                    SELECT COUNT (1)
                      INTO l_count
                      FROM mes4.r_tr_sn a, mes4.r_station_wip b
                     WHERE     b.kp_no = a.cust_kp_no
                           AND a.tr_sn = b.tr_sn
                           AND b.station = l_ap_station
                           AND a.tr_sn = g_tr_sn;

                    IF l_count = 0
                    THEN
                        res := 'SCM-T03308:' || l_slot;
                        RAISE l_exit;
                    END IF;
                END IF;

                SELECT station, slot_no
                  INTO l_machine, l_slot
                  FROM mes4.r_station_wip
                 WHERE tr_sn = g_tr_sn AND ROWNUM = 1;

                IF l_machine = l_ap_station
                THEN
                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                data8,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 '0',
                                 'OLD TR SN',
                                 l_machine,
                                 l_slot,
                                 '0',
                                 'CHANG-KP',
                                 SYSDATE);

                    COMMIT;


                    IF    SUBSTR (l_ap_station, 4, 1) = 'A'
                       OR SUBSTR (l_ap_station, 4, 1) = 'R'
                       OR SUBSTR (l_ap_station, 4, 1) = 'L'
                    THEN
                        l_next_input := 'NEW TR SN';
                    ELSIF l_is_apmachine = 'Y'
                    THEN
                        l_next_input := 'STENCIL SN';
                    ELSE
                        l_next_input := 'FEEDER NO';
                    END IF;

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'OLD TR SN',
                                 g_tr_sn,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    res := 'OK OLD TR SN';

                    COMMIT;
                --               END IF;
                ELSE
                    res := 'SCM-T03169:' || l_machine || ',' || l_slot;
                END IF;
            ELSIF l_this_input = 'FEEDER NO'
            THEN
                SELECT data5, data6
                  INTO l_machine, l_slot
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data8 = 'CHANG-KP';

                MES1.pkg_smt_scan_web_check.check_feederno_WEB2 (
                    UPPER (mydata),
                    l_machine,
                    l_slot,
                    'Y',
                    res);

                IF SUBSTR (res, 1, 2) = 'OK' --+以下一句為﹕PCH﹕2006-08-12-ADD--+------------------
                                             OR SUBSTR (res, 1, 6) = 'NOTICE'
                --+以上一句為﹕PCH﹕2006-08-12-ADD--+------------------
                THEN
                    MES1.pkg_smt_scan_web_check.CHECK_STATION_MACHINE_WEB (
                        l_machine,
                        'MACHINE',
                        l_emp,
                        res);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        l_next_input := 'NEW TR SN';

                        INSERT INTO mes4.r_ap_temp (data1,
                                                    data2,
                                                    data3,
                                                    data4,
                                                    data5,
                                                    data6,
                                                    data7,
                                                    work_time)
                             VALUES ('SCADA-GW28',
                                     g_stationno,
                                     TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                     'FEEDER NO',
                                     UPPER (mydata),
                                     l_next_input,
                                     '0',
                                     SYSDATE);

                        COMMIT;
                        res := 'OK FEEDER NO';
                    END IF;
                END IF;
            ELSIF l_this_input = 'STENCIL SN'
            THEN
                SELECT COUNT (1)
                  INTO l_count
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'MACHINE'
                       AND ROWNUM = 1;

                IF l_count > 0
                THEN
                    SELECT data5
                      INTO l_machine
                      FROM mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data4 = 'MACHINE'
                           AND ROWNUM = 1;
                ELSE
                    SELECT data5
                      INTO l_machine
                      FROM mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data3 = '0'
                           AND ROWNUM = 1;
                END IF;


                SELECT data5
                  INTO l_emp
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'EMP'
                       AND ROWNUM = 1;

                SELECT COUNT (1)
                  INTO L_COUNT
                  FROM MES4.R_STATION_WIP
                 WHERE STATION = L_MACHINE AND ROWNUM = 1;

                IF L_COUNT > 0
                THEN
                    SELECT WO
                      INTO L_WO
                      FROM MES4.R_STATION_WIP
                     WHERE STATION = L_MACHINE AND ROWNUM = 1;
                END IF;

                L_LINE := SUBSTR (l_machine, 1, 5);



                --钢网上线前检查
                MES1.check_stencil ('STENCILCONTROL_ONLINECHECK',
                                    mydata,
                                    '',
                                    '',
                                    l_emp,
                                    L_LINE,
                                    L_MACHINE,
                                    L_WO,
                                    l_emp,
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    USER_CUSOR);

                FETCH USER_CUSOR INTO l_res;

                CLOSE USER_CUSOR;

                res := l_res;

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    res := res;
                    RAISE l_exit;
                END IF;

                --钢网上线
                MES1.check_stencil ('STENCILCONTROL_ONLINE',
                                    mydata,
                                    '',
                                    '',
                                    l_emp,
                                    L_LINE,
                                    L_MACHINE,
                                    L_WO,
                                    l_emp,
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    USER_CUSOR);

                -- check_slotno (mydata, l_machine, res);

                FETCH USER_CUSOR INTO l_res;

                CLOSE USER_CUSOR;

                res := l_res;

                -- res := 'OK';

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    l_next_input := 'NEW TR SN';


                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'STENCIL SN',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                END IF;
            ELSIF l_this_input = 'NEW TR SN'
            THEN
                res := 'SCM-T03379:' || mydata;

                SELECT mes1.GET_SCAN_SN_ALLPART (mydata)
                  INTO g_tr_sn
                  FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    --res := '料盘序号不存在 6,仓库未发料,' || mydata;
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                --检查条码是否是合法条码
                SELECT COUNT (1)
                  INTO l_count
                  FROM mes4.r_tr_sn
                 WHERE tr_sn = g_tr_sn;

                IF l_count < 1
                THEN
                    res := 'SCM-T03444:' || mydata;
                    RAISE l_exit;
                END IF;

                /**
                 * 2025-6-12 新增上料前检查是否兰吉尔物料,兰吉尔物料卡控S开头的条码
                 */
                select COUNT (1) INTO l_count from mes4.customer_materials m where m.material=(select r.cust_kp_no from mes4.r_2d_sn_relation r where r.barcode_2d=mydata);

                IF l_count > 0
                THEN
                    IF substr(upper(mydata),1,1) <> 'S'
                    THEN
                        res := 'SCM-T03708:' || mydata ; --'兰吉尔物料上料必须是S开头的条码';
                        RAISE l_exit;
                    END IF;

                    select count(1) into l_count from mes4.customer_sns s where s.sn=mydata;
                    IF l_count < 1 THEN
                        res := '当前上料条码不是兰吉尔物料条码'; --'兰吉尔物料上料必须是S开头的条码';
                        RAISE l_exit;
                    end if;

                end if;

                IF INSTR (l_ap_station, 'LM') > 0
                THEN
                    --判断是否贴标机上料
                    l_machine := l_ap_station;
                    l_slot := '';
                ELSE
                    SELECT data5, data6
                      INTO l_machine, l_slot
                      FROM mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data8 = 'CHANG-KP';
                END IF;

                --2024-11-7增加锡膏换料检查 end
                --判断是否印刷机,如果是印刷机换料
                IF INSTR(l_ap_station, 'AP')>0 THEN
                  SELECT COUNT (1)
                      INTO L_COUNT
                      FROM mes4.C_SOLDERPASTE_BASE
                     WHERE KP_NO = (SELECT cust_kp_no
                                      FROM mes4.r_tr_sn
                                     WHERE tr_sn = g_tr_sn);
                    --如果是锡膏换料
                    IF L_COUNT > 0
                    THEN
                      --是锡膏料号，检查钢网,刮刀配套使用的锡膏是否更换
                      res :=
                          MES1.CHECK_STEANDFIX_KPMGR (
                              p_type      => 5,
                              p_trsn      => g_tr_sn,
                              p_station   => l_machine,
                              p_wo        => '',
                              p_line =>'');

                      IF SUBSTR (res, 1, 2) <> 'OK'
                      THEN
                          RAISE l_exit;
                      END IF;
                    END IF;
                END IF;
                --2024-11-7增加锡膏换料检查 end

                --Check Bincode start
                --检查BinCode换料确认--
                res := 'SCM-T03394:' || g_tr_sn;
                mes1.check_material_mfr_change (res,
                                                'SMT_BINCODE_CONTROL_SLOT',
                                                g_tr_sn,
                                                l_slot,
                                                g_stationno);

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    RAISE l_exit;
                END IF;

                mes1.check_material_mfr_change (res,
                                                'SMT_BINCODE_CONTROL_LINE',
                                                g_tr_sn,
                                                l_slot,
                                                g_stationno);

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    RAISE l_exit;
                END IF;

                --Check Bincode end


                IF    SUBSTR (l_machine, 4, 1) = 'A'
                   OR SUBSTR (l_machine, 4, 1) = 'R'
                THEN
                    l_feeder := 'N/A';
                ELSIF l_is_apmachine = 'Y'
                THEN
                    l_slot := 'N/A';

                    SELECT COUNT (1)
                      INTO L_COUNT
                      FROM mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data4 = 'STENCIL SN'
                           AND ROWNUM = 1;

                    IF L_COUNT > 0
                    THEN
                        SELECT data5
                          INTO l_feeder
                          FROM mes4.r_ap_temp
                         WHERE     data1 = 'SCADA-GW28'
                               AND data2 = g_stationno
                               AND data4 = 'STENCIL SN'
                               AND ROWNUM = 1;
                    ELSE
                        l_feeder := 'N/A';
                    END IF;
                ELSE
                    SELECT data5
                      INTO l_feeder
                      FROM mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data4 = 'FEEDER NO'
                           AND data6 = 'NEW TR SN'
                           AND ROWNUM = 1;
                END IF;

                -----------------add by wyz 2008/06/06--------------------
                OPEN get_check_emp_value;
                
                --生产机配置为N/Y
                FETCH get_check_emp_value
                    INTO tmp_check_emp_value, tmp_check_mfr_emp;

                IF get_check_emp_value%FOUND
                THEN
                    IF tmp_check_emp_value = 'Y'
                    THEN
                        l_next_input := 'CHECK EMP';

                        OPEN old_trsn (g_tr_sn);

                        FETCH old_trsn INTO l_work_flag, l_location_flag;

                        IF old_trsn%FOUND
                        THEN
                            IF l_work_flag = '1'
                            THEN
                                res := 'SCM-T03163';
                            ELSIF l_work_flag = '0'
                            THEN
                                IF l_location_flag = '0'
                                THEN
                                    res := 'SCM-T03129';
                                ELSIF l_location_flag = '1'
                                THEN
                                    res := 'SCM-T03128';
                                ELSIF l_location_flag = '2'
                                THEN
                                    --多一槍CHECK EMP 時，先檢查TR_SN狀態--
                                    -- mes1.check_trsn_on_kp_temp
                                    MES1.pkg_smt_scan_web_check.check_trsn_on_kp_temp_web (
                                        g_tr_sn,
                                        l_emp,
                                        l_machine,
                                        l_slot,
                                        l_feeder,
                                        'MACHINE',
                                        g_stationno,
                                        res);

                                    IF SUBSTR (res, 1, 2) = 'OK'
                                    THEN
                                        INSERT INTO mes4.r_ap_temp (
                                                        data1,
                                                        data2,
                                                        data3,
                                                        data4,
                                                        data5,
                                                        data6,
                                                        data7,
                                                        work_time)
                                                 VALUES (
                                                            'SCADA-GW28',
                                                            g_stationno,
                                                            TO_CHAR (
                                                                  TO_NUMBER (
                                                                      l_sequence)
                                                                + 1),
                                                            'NEW TR SN',
                                                            g_tr_sn,
                                                            l_next_input,
                                                            '0',
                                                            SYSDATE);

                                        COMMIT;
                                        res := 'OK TR SN';
                                    END IF;
                                ELSIF l_location_flag = '3'
                                THEN
                                    res := 'SCM-T03150';
                                ELSE
                                    res := 'SCM-T03153';
                                END IF;
                            ELSIF l_work_flag = '2'
                            THEN
                                res := 'SCM-T03164';
                            ELSIF l_work_flag = '3'
                            THEN
                                res := 'SCM-T03165';
                            ELSE
                                res := 'SCM-T03153';
                            END IF;
                        ELSE
                            res := 'SCM-T03153';
                        END IF;
                    ELSIF     tmp_check_emp_value = 'N'
                          AND tmp_check_mfr_emp = 'Y'
                    THEN
                        l_next_input := 'CHECK EMP';
                        --多一槍CHECK EMP 時，先檢查TR_SN狀態--
                        --mes1.check_trsn_on_kp_temp
                        MES1.pkg_smt_scan_web_check.check_trsn_on_kp_temp_web (
                            g_tr_sn,
                            l_emp,
                            l_machine,
                            l_slot,
                            l_feeder,
                            'MACHINE',
                            g_stationno,
                            res);

                        IF SUBSTR (res, 1, 2) <> 'OK'
                        THEN
                            RAISE l_exit;
                        END IF;



                        mes1.check_material_mfr_change (
                            res,
                            'SMT_ACTION_B_CHECKEMP',
                            g_tr_sn,
                            l_slot,
                            l_machine);

                        IF SUBSTR (res, 1, 9) = 'DIFFERENT'
                        THEN
                            INSERT INTO mes4.r_ap_temp (data1,
                                                        data2,
                                                        data3,
                                                        data4,
                                                        data5,
                                                        data6,
                                                        data7,
                                                        work_time)
                                     VALUES (
                                                'SCADA-GW28',
                                                g_stationno,
                                                TO_CHAR (
                                                      TO_NUMBER (l_sequence)
                                                    + 1),
                                                'NEW TR SN',
                                                g_tr_sn,
                                                l_next_input,
                                                '0',
                                                SYSDATE);

                            COMMIT;
                            res := 'OK,' || res;
                        ELSIF SUBSTR (res, 1, 2) = 'OK'
                        THEN
                            --扫描新条码前先下料start add by lyl 20190822

                            SELECT COUNT (1)
                              INTO L_COUNT
                              FROM mes4.r_ap_temp
                             WHERE     data2 = g_stationno
                                   AND data4 = 'OLD TR SN'
                                   AND DATA8 IS NULL;

                            IF L_COUNT > 0
                            THEN
                                SELECT data5
                                  INTO l_temp_trsn
                                  FROM mes4.r_ap_temp
                                 WHERE     data2 = g_stationno
                                       AND data4 = 'OLD TR SN'
                                       AND DATA8 IS NULL;
                            ELSE
                                IF INSTR (l_ap_station, 'LM') > 0
                                THEN
                                    SELECT COUNT (1)
                                      INTO l_count
                                      FROM mes4.r_STATION_wip
                                     WHERE     station = l_ap_station
                                           AND TR_SN IS NOT NULL;

                                    IF l_count > 0
                                    THEN
                                        SELECT TR_SN
                                          INTO l_temp_trsn
                                          FROM mes4.r_STATION_wip
                                         WHERE     station = l_ap_station
                                               AND TR_SN IS NOT NULL;
                                    ELSE
                                        res := 'SCM-T03643';
                                        RAISE l_exit;
                                    END IF;
                                ELSE
                                    res := 'SCM-T03528';
                                    RAISE l_exit;
                                END IF;
                            END IF;

                            null_offkp_trsn (l_temp_trsn,
                                             'MACHINE',
                                             l_emp,
                                             res);

                            IF SUBSTR (res, 1, 2) = 'OK'
                            THEN
                                MES1.pkg_smt_scan_web_check.CHECK_STATION_MACHINE_WEB (
                                    l_machine,
                                    'MACHINE',
                                    l_emp,
                                    res);

                                IF SUBSTR (res, 1, 2) <> 'OK'
                                THEN
                                    RAISE l_exit;
                                END IF;
                            ELSE
                                RAISE l_exit;
                            END IF;

                            --  扫描新条码前先下料end add by lyl 20190822

                            MES1.pkg_smt_scan_web_check.CHECK_TRSN_ON_KP_WEB (
                                g_tr_sn,
                                l_emp,
                                l_machine,
                                l_slot,
                                l_feeder,
                                'MACHINE',
                                res);

                            IF SUBSTR (res, 1, 2) = 'OK'
                            THEN
                                mes1.check_end ('END',
                                                l_machine,
                                                l_emp,
                                                res);

                                DELETE FROM
                                    mes4.r_ap_temp
                                      WHERE     data1 = 'SCADA-GW28'
                                            AND data2 = g_stationno
                                            AND data3 NOT IN ('2', '1');

                                COMMIT;

                                IF     INSTR (l_machine, 'AP') < 1
                                   AND INSTR (l_machine, 'LM') < 1
                                THEN
                                    mes1.z_station_shortage_sp (
                                        'CHANGE_MATERIAL',
                                        '',
                                        l_machine,
                                        l_slot,
                                        '',
                                        g_tr_sn,
                                        '',
                                        '',
                                        '',
                                        '',
                                        '',
                                        l_emp,
                                        res);
                                ELSE
                                    mes1.z_station_shortage_sp (
                                        'CHANGE_MATERIAL_DIP',
                                        '',
                                        l_machine,
                                        l_slot,
                                        '',
                                        g_tr_sn,
                                        '',
                                        '',
                                        '',
                                        '',
                                        '',
                                        l_emp,
                                        res);
                                END IF;

                                IF SUBSTR (res, 1, 2) <> 'OK'
                                THEN
                                    res := 'OK';
                                END IF;
                            END IF;
                        ELSE
                            res := res;
                        END IF;
                    -----------------add by wyz 2008/06/06--------------------

                    -----------------modeify by wyz 2008/06/06----------------
                    ELSE
                        --扫描新条码前先下料start add by lyl 20190822

                        SELECT COUNT (1)
                          INTO L_COUNT
                          FROM mes4.r_ap_temp
                         WHERE     data2 = g_stationno
                               AND data4 = 'OLD TR SN'
                               AND DATA8 IS NULL;

                        IF L_COUNT > 0
                        THEN
                            SELECT data5
                              INTO l_temp_trsn
                              FROM mes4.r_ap_temp
                             WHERE     data2 = g_stationno
                                   AND data4 = 'OLD TR SN'
                                   AND DATA8 IS NULL;
                        ELSE
                            res := 'SCM-T03528';
                            RAISE l_exit;
                        END IF;

                        null_offkp_trsn (l_temp_trsn,
                                         'MACHINE',
                                         l_emp,
                                         res);

                        IF SUBSTR (res, 1, 2) = 'OK'
                        THEN
                            MES1.pkg_smt_scan_web_check.CHECK_STATION_MACHINE_WEB (
                                l_machine,
                                'MACHINE',
                                l_emp,
                                res);

                            IF SUBSTR (res, 1, 2) <> 'OK'
                            THEN
                                RAISE l_exit;
                            END IF;
                        ELSE
                            RAISE l_exit;
                        END IF;

                        --  扫描新条码前先下料end add by lyl 20190822
                        MES1.pkg_smt_scan_web_check.CHECK_TRSN_ON_KP_WEB (
                            g_tr_sn,
                            l_emp,
                            l_machine,
                            l_slot,
                            l_feeder,
                            'MACHINE',
                            res);

                        IF SUBSTR (res, 1, 2) = 'OK'
                        THEN
                            check_end ('END',
                                       l_machine,
                                       l_emp,
                                       res);

                            DELETE FROM
                                mes4.r_ap_temp
                                  WHERE     data1 = 'SCADA-GW28'
                                        AND data2 = g_stationno
                                        AND data3 NOT IN ('0', '1', '2');

                            COMMIT;

                            ---SMT 物料預警-------
                            IF     INSTR (l_machine, 'AP') < 1
                               AND INSTR (l_machine, 'LM') < 1
                            THEN
                                mes1.z_station_shortage_sp (
                                    'CHANGE_MATERIAL',
                                    '',
                                    l_machine,
                                    l_slot,
                                    '',
                                    g_tr_sn,
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    l_emp,
                                    res);
                            ELSE
                                mes1.z_station_shortage_sp (
                                    'CHANGE_MATERIAL_DIP',
                                    '',
                                    l_machine,
                                    l_slot,
                                    '',
                                    g_tr_sn,
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    l_emp,
                                    res);
                            END IF;

                            IF SUBSTR (res, 1, 2) <> 'OK'
                            THEN
                                res := 'OK';
                            END IF;
                        END IF;
                    END IF;
                END IF;

                -----------------modeify by wyz 2008/06/06--------------------
                CLOSE get_check_emp_value;

                --2024-1-15增加锡膏换料管控 start reaper
                --判断是否印刷机,如果是印刷机换料
                IF INSTR(l_ap_station, 'AP')>0 THEN
                  SELECT COUNT (1)
                      INTO L_COUNT
                      FROM mes4.C_SOLDERPASTE_BASE
                     WHERE KP_NO = (SELECT cust_kp_no
                                      FROM mes4.r_tr_sn
                                     WHERE tr_sn = g_tr_sn);
                    --如果是锡膏换料
                    IF L_COUNT > 0
                    THEN
                      --是锡膏料号，检查钢网,刮刀配套使用的锡膏是否更换
                      res :=
                          MES1.CHECK_STEANDFIX_KPMGR (
                              p_type      => 3,
                              p_trsn      => g_tr_sn,
                              p_station   => l_machine,
                              p_wo        => '',
                              p_line =>'');

                      IF SUBSTR (res, 1, 2) <> 'OK'
                      THEN
                          RAISE l_exit;
                      END IF;
                    END IF;
                END IF;
                --2024-1-15增加锡膏换料管控 end

            ELSIF l_this_input = 'CHECK EMP'
            THEN
                SELECT data5, data6
                  INTO l_machine, l_slot
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data8 = 'CHANG-KP';

                SELECT data5
                  INTO l_feeder
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'FEEDER NO'
                       AND data6 = 'NEW TR SN'
                       AND ROWNUM = 1;

                OPEN get_check_emp_value;

                FETCH get_check_emp_value
                    INTO tmp_check_emp_value, tmp_check_mfr_emp;

                IF get_check_emp_value%FOUND
                THEN
                    IF tmp_check_mfr_emp = 'Y'
                    THEN
                        SELECT COUNT (emp_no)
                          INTO i_temp_emp_privilage
                          FROM mes1.c_ap_config
                         WHERE emp_no = mydata AND function_name = 'CHECKEMP';
                    END IF;

                    CLOSE get_check_emp_value;
                END IF;

                SELECT data5
                  INTO l_temp_new_trsn
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'NEW TR SN'
                       AND data6 = 'CHECK EMP';

                SELECT data5
                  INTO l_temp_old_trsn
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'OLD TR SN'
                       AND data6 = 'FEEDER NO';

                --AND data3 = '3';
                IF i_temp_emp_privilage > 0
                THEN
                    IF mydata <> l_emp OR mydata='80021081'
                    THEN
                        --log for MFR_CHANGE WHEN ME UNLOCK   ROBERT
                        mes1.check_material_mfr_change (res,
                                                        'LOG_WHEN_MEUNLOCK',
                                                        mydata,
                                                        '',
                                                        g_stationno);

                        IF SUBSTR (res, 1, 2) <> 'OK'
                        THEN
                            RAISE l_exit;
                        END IF;
                         l_next_input := 'CONFIRM PASSWORD';
                         MES1.INSERT_NEXT_INPUT ('INSERT_NEXT_INPUT',
                                            'SCADA-GW28',
                                            g_stationno,
                                            l_sequence,
                                            l_this_input,
                                            mydata,
                                            l_next_input,
                                            '0',
                                            '',
                                            RES);

                    ELSE
                        res := 'SCM-T03412';
                        RAISE l_exit;
                    END IF;
                ELSE
                    res := 'SCM-T03413';
                    RAISE l_exit;
                END IF;
            ELSIF l_this_input = 'CONFIRM PASSWORD'
            THEN

                 SELECT data5, data6
                  INTO l_machine, l_slot
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data8 = 'CHANG-KP';

                SELECT data5
                  INTO l_feeder
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'FEEDER NO'
                       AND data6 = 'NEW TR SN'
                       AND ROWNUM = 1;
                l_emp :=
                    MES1.GETALL_INPUT_DATA ('EMP',
                                            g_stationno,
                                            '',
                                            '',
                                            '');
                  L_CHECK_emp :=   MES1.GETALL_INPUT_DATA ('CHECK EMP',
                                            g_stationno,
                                            '',
                                            '',
                                            '') ;
                l_temp_new_trsn :=
                    MES1.GETALL_INPUT_DATA ('NEW TR SN',
                                            g_stationno,
                                            '',
                                            '',
                                            '');



                CHECK_PASSWORD_ONLIN (mydata,
                                      L_CHECK_emp,
                                      l_machine,
                                      res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    MES1.Z_EXCUT_CHANGE_COMPON_PASS (l_temp_new_trsn,
                                              l_emp,L_CHECK_emp,
                                              l_machine,
                                              l_slot,
                                              l_feeder,
                                              g_stationno,
                                              RES);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                          DELETE FROM  mes4.r_ap_temp   WHERE     data1 = 'SCADA-GW28'   AND data2 = g_stationno     AND data3 NOT IN ('0', '1', '2');
                    ELSE
                        RAISE l_exit;
                    END IF;
                END IF;
            ELSE
                res := 'SCM-T03082';
                RAISE l_exit;
            END IF;
        ---------------------------------------------------------------
        --------------------  ACTION-M-F用于機台備料  -----------------
        ---------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-F'
        THEN
            IF l_this_input = 'TRAVEL SN WO'
            THEN
                MES1.pkg_smt_scan_web_check.check_travelsn_buffer_web (
                    mydata,
                    l_emp,
                    l_ap_station,
                    res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    l_next_input := 'SLOT NO/END';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'TRAVEL SN WO',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                END IF;
            ELSIF l_this_input = 'SLOT NO/END'
            THEN
                SELECT data5
                  INTO l_travelsn
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'TRAVEL SN WO'
                       AND ROWNUM = 1;

                IF mydata = 'END'
                THEN
                    MES1.pkg_smt_scan_web_check.check_end_buffer_web (
                        mydata,
                        l_travelsn,
                        l_emp,
                        res);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno;

                        COMMIT;
                    ELSIF SUBSTR (res, 1, 19) = 'BUFFER NOT FINISHED'
                    THEN
                        l_next_input := 'SHORTAGE CONFIRM/SLOT NO';

                        INSERT INTO mes4.r_ap_temp (data1,
                                                    data2,
                                                    data3,
                                                    data4,
                                                    data5,
                                                    data6,
                                                    data7,
                                                    work_time)
                             VALUES ('SCADA-GW28',
                                     g_stationno,
                                     TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                     'SLOT NO/END',
                                     mydata,
                                     l_next_input,
                                     '0',
                                     SYSDATE);

                        COMMIT;
                    END IF;
                ELSE
                    MES1.pkg_smt_scan_web_check.CHECK_SLOTNO_BUFFER_WEB (
                        mydata,
                        l_travelsn,
                        l_ap_station,
                        res);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        IF    SUBSTR (l_ap_station, 4, 1) = 'A'
                           OR SUBSTR (l_ap_station, 4, 1) = 'R'
                        THEN
                            l_next_input := 'TR SN';
                        ELSE
                            l_next_input := 'FEEDER NO';
                        END IF;

                        INSERT INTO mes4.r_ap_temp (data1,
                                                    data2,
                                                    data3,
                                                    data4,
                                                    data5,
                                                    data6,
                                                    data7,
                                                    work_time)
                             VALUES ('SCADA-GW28',
                                     g_stationno,
                                     TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                     'SLOT NO/END',
                                     mydata,
                                     l_next_input,
                                     '0',
                                     SYSDATE);

                        COMMIT;
                    ELSE
                        OPEN slot_temp;

                        FETCH slot_temp INTO l_slot_temp;

                        IF slot_temp%FOUND
                        THEN
                            WHILE slot_temp%FOUND
                            LOOP
                                MES1.pkg_smt_scan_web_check.CHECK_SLOTNO_BUFFER_WEB (
                                    l_slot_temp,
                                    l_travelsn,
                                    l_ap_station,
                                    res);

                                IF SUBSTR (res, 1, 2) = 'OK'
                                THEN
                                    IF    SUBSTR (l_ap_station, 4, 1) = 'A'
                                       OR SUBSTR (l_ap_station, 4, 1) = 'R'
                                    THEN
                                        l_next_input := 'TR SN';
                                    ELSE
                                        l_next_input := 'FEEDER NO';
                                    END IF;

                                    INSERT INTO mes4.r_ap_temp (data1,
                                                                data2,
                                                                data3,
                                                                data4,
                                                                data5,
                                                                data6,
                                                                data7,
                                                                work_time)
                                             VALUES (
                                                        'SCADA-GW28',
                                                        g_stationno,
                                                        TO_CHAR (
                                                              TO_NUMBER (
                                                                  l_sequence)
                                                            + 1),
                                                        'SLOT NO/END',
                                                        l_slot_temp,
                                                        l_next_input,
                                                        '0',
                                                        SYSDATE);

                                    COMMIT;
                                END IF;

                                FETCH slot_temp INTO l_slot_temp;
                            END LOOP;

                            CLOSE slot_temp;
                        ELSE
                            OPEN slot_track_temp;

                            FETCH slot_track_temp INTO l_slot;

                            IF slot_track_temp%FOUND
                            THEN
                                CLOSE slot_track_temp;

                                res := 'SCM-T03118:' || mydata;
                            ELSE
                                CLOSE slot_track_temp;
                            END IF;

                            CLOSE slot_temp;
                        END IF;
                    END IF;
                END IF;
            ELSIF l_this_input = 'FEEDER NO'
            THEN
                SELECT data5
                  INTO l_travelsn
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'TRAVEL SN WO'
                       AND ROWNUM = 1;

                OPEN temp_track;

                FETCH temp_track INTO l_slot;

                IF temp_track%FOUND
                THEN
                    IF INSTR (mydata, 'TRACK') > 0
                    THEN
                        l_track_tmp :=
                            SUBSTR (mydata, INSTR (mydata, 'TRACK') + 5, 1);

                        IF l_track_tmp = 'L'
                        THEN
                            l_track := '1';
                        ELSIF l_track_tmp = 'M'
                        THEN
                            l_track := '2';
                        ELSIF l_track_tmp = 'R'
                        THEN
                            l_track := '3';
                        END IF;

                        OPEN slot_track_tmp;

                        FETCH slot_track_tmp INTO l_slot;

                        IF slot_track_tmp%NOTFOUND
                        THEN
                            CLOSE slot_track_tmp;

                            CLOSE temp_track;

                            res := 'SCM-T03089';
                            RAISE l_exit;
                        END IF;

                        CLOSE slot_track_tmp;

                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno
                                    AND data4 = 'SLOT NO/END'
                                    AND data6 = 'FEEDER NO'
                                    AND data5 NOT LIKE '%-' || l_track || '%';
                    END IF;
                END IF;

                CLOSE temp_track;

                SELECT data5
                  INTO l_slot
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'SLOT NO/END'
                       AND data3 =
                           (SELECT MAX (TO_NUMBER (data3))
                              FROM mes4.r_ap_temp
                             WHERE     data1 = 'SCADA-GW28'
                                   AND data2 = g_stationno);

                MES1.pkg_smt_scan_web_check.check_feederno_buffer_web (
                    mydata,
                    l_travelsn,
                    l_ap_station,
                    l_slot,
                    res);

                IF SUBSTR (res, 1, 2) = 'OK' --+以下一句為﹕PCH﹕2006-08-12-ADD--+------------------
                                             OR SUBSTR (res, 1, 6) = 'NOTICE'
                --+以上一句為﹕PCH﹕2006-08-12-ADD--+------------------
                THEN
                    l_next_input := 'TR SN';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'FEEDER NO',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                END IF;
            ELSIF l_this_input = 'TR SN'
            THEN
                res := 'SCM-T03379:' || mydata;

                SELECT mes1.get_scan_sn (mydata) INTO g_tr_sn FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    --res := '料盘序号不存在 7,仓库未发料' || mydata;
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                SELECT data5
                  INTO l_travelsn
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'TRAVEL SN WO'
                       AND ROWNUM = 1;

                SELECT data5
                  INTO l_feeder
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'FEEDER NO'
                       AND ROWNUM = 1;

                SELECT data5
                  INTO l_slot
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'SLOT NO/END'
                       AND data3 =
                           (SELECT MAX (TO_NUMBER (data3))
                              FROM mes4.r_ap_temp
                             WHERE     data1 = 'SCADA-GW28'
                                   AND data2 = g_stationno
                                   AND data4 = 'SLOT NO/END');

                MES1.pkg_smt_scan_web_check.check_trsn_buffer_web (
                    g_tr_sn,
                    l_emp,
                    l_travelsn,
                    l_slot,
                    l_feeder,
                    l_ap_station,
                    res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    DELETE FROM
                        mes4.r_ap_temp
                          WHERE     data1 = 'SCADA-GW28'
                                AND data2 = g_stationno
                                AND data4 IN
                                        ('SLOT NO',
                                         'FEEDER NO',
                                         'SLOT NO/END');

                    COMMIT;
                END IF;
            --注意檢挑
            ELSIF l_this_input = 'SHORTAGE CONFIRM/SLOT NO'
            THEN
                IF mydata = 'CONFIRM-S'
                THEN
                    l_next_input := 'CONFIRM PASSWORD';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'SHORTAGE CONFIRM',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK CONFIRM CODE';
                ELSE
                    SELECT data5
                      INTO l_travelsn
                      FROM mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data4 = 'TRAVEL SN WO'
                           AND ROWNUM = 1;

                    MES1.pkg_smt_scan_web_check.CHECK_SLOTNO_BUFFER_WEB (
                        mydata,
                        l_travelsn,
                        l_ap_station,
                        res);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        IF    SUBSTR (l_ap_station, 4, 1) = 'A'
                           OR SUBSTR (l_ap_station, 4, 1) = 'R'
                        THEN
                            l_next_input := 'TR SN';
                        ELSE
                            l_next_input := 'FEEDER NO';
                        END IF;

                        INSERT INTO mes4.r_ap_temp (data1,
                                                    data2,
                                                    data3,
                                                    data4,
                                                    data5,
                                                    data6,
                                                    data7,
                                                    work_time)
                             VALUES ('SCADA-GW28',
                                     g_stationno,
                                     TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                     'SLOT NO/END',
                                     mydata,
                                     l_next_input,
                                     '0',
                                     SYSDATE);

                        COMMIT;
                    ELSE
                        OPEN slot_temp;

                        FETCH slot_temp INTO l_slot_temp;

                        IF slot_temp%FOUND
                        THEN
                            WHILE slot_temp%FOUND
                            LOOP
                                MES1.pkg_smt_scan_web_check.CHECK_SLOTNO_BUFFER_WEB (
                                    l_slot_temp,
                                    l_travelsn,
                                    l_ap_station,
                                    res);

                                IF SUBSTR (res, 1, 2) = 'OK'
                                THEN
                                    IF    SUBSTR (l_ap_station, 4, 1) = 'A'
                                       OR SUBSTR (l_ap_station, 4, 1) = 'R'
                                    THEN
                                        l_next_input := 'TR SN';
                                    ELSE
                                        l_next_input := 'FEEDER NO';
                                    END IF;

                                    INSERT INTO mes4.r_ap_temp (data1,
                                                                data2,
                                                                data3,
                                                                data4,
                                                                data5,
                                                                data6,
                                                                data7,
                                                                work_time)
                                             VALUES (
                                                        'SCADA-GW28',
                                                        g_stationno,
                                                        TO_CHAR (
                                                              TO_NUMBER (
                                                                  l_sequence)
                                                            + 1),
                                                        'SLOT NO/END',
                                                        l_slot_temp,
                                                        l_next_input,
                                                        '0',
                                                        SYSDATE);

                                    COMMIT;
                                END IF;

                                FETCH slot_temp INTO l_slot_temp;
                            END LOOP;

                            CLOSE slot_temp;
                        ELSE
                            OPEN slot_track_temp;

                            FETCH slot_track_temp INTO l_slot;

                            IF slot_track_temp%FOUND
                            THEN
                                CLOSE slot_track_temp;

                                res := 'SLOT ALREADY FULL/' || mydata;
                            ELSE
                                CLOSE slot_track_temp;
                            END IF;

                            CLOSE slot_temp;
                        END IF;
                    END IF;
                END IF;
            ELSIF l_this_input = 'CONFIRM PASSWORD'
            THEN
                SELECT data5
                  INTO l_travelsn
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'TRAVEL SN WO'
                       AND ROWNUM = 1;

                check_password_buffer (mydata,
                                       l_emp,
                                       l_travelsn,
                                       res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    DELETE FROM mes4.r_ap_temp
                          WHERE data1 = 'SCADA-GW28' AND data2 = g_stationno;
                END IF;
            END IF;
        ELSIF l_action_code = 'ACTION-M-FQ'
        THEN
            IF l_this_input = 'TRAVEL SN WO'
            THEN
                MES1.pkg_smt_scan_web_check.check_travelsn_buffer_web (
                    mydata,
                    l_emp,
                    l_ap_station,
                    res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    l_next_input := 'TR SN';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'TRAVEL SN WO',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                END IF;
            ELSIF l_this_input = 'TR SN'
            THEN
                res := 'SCM-T03379:' || mydata;

                SELECT mes1.get_scan_sn (mydata) INTO g_tr_sn FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    --res := '料盘序号不存在  FQ,仓库未发料,' || mydata;
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                SELECT data5
                  INTO l_travelsn
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'TRAVEL SN WO'
                       AND ROWNUM = 1;


                MES1.pkg_smt_scan_web_check.check_material_slot_web (
                    mydata,
                    l_travelsn,
                    l_emp,
                    l_ap_station,
                    res);
            END IF;
        ELSIF l_action_code = 'ACTION-M-G'
        THEN
            IF l_this_input = 'TR SN'
            THEN
                res := 'SCM-T03379:' || mydata;

                SELECT mes1.get_scan_sn (mydata) INTO g_tr_sn FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    --res := '料盘序号不存在 8,仓库未发料' || mydata;
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                offkp_trsn_buffer (g_tr_sn, l_emp, res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    UPDATE mes4.r_ap_temp
                       SET data6 = 'TR SN/END'
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data4 = 'ACTION CODE';

                    COMMIT;
                END IF;
            ELSIF l_this_input = 'TR SN/END'
            THEN
                res := 'SCM-T03379:' || mydata;

                SELECT mes1.get_scan_sn (mydata) INTO g_tr_sn FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    --res := '料盘序号不存在 9,仓库未发料' || mydata;
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                offkp_trsn_buffer (g_tr_sn, l_emp, res);

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    IF mydata = 'END'
                    THEN
                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno;

                        COMMIT;
                        res := 'OK END';
                    ELSE
                        res := 'ERROR TR SN';
                    END IF;
                END IF;
            END IF;
        ---------------------------------------------------------------
        ----------------ACTION-M-SO 刮刀上線作業代碼---------------
        ---------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-SO'
        THEN
            IF l_this_input = 'TRAVEL SN WO'
            THEN
                SELECT COUNT (1)
                  INTO l_count
                  FROM mes4.r_station_wip
                 WHERE wo = mydata AND STATION = l_ap_station;

                IF l_count > 0
                THEN
                    l_next_input := 'SCRAPER SN';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'TRAVEL SN WO',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK TRAVEL SN WO';
                ELSE
                    res := 'SCM-T03385:' || mydata;
                    RAISE l_exit;
                END IF;
            ELSIF l_this_input = 'SCRAPER SN'
            THEN
                res := 'SCM-T03407';

                SELECT data5
                  INTO l_wo_temp
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'TRAVEL SN WO'
                       AND ROWNUM = 1;

                check_scraper_sn (UPPER (mydata),
                                  UPPER (l_ap_station),
                                  l_wo_temp,
                                  '0',
                                  res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    SELECT data5
                      INTO l_emp
                      FROM mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data4 = 'EMP'
                           AND ROWNUM = 1;

                    z_scraper_save (UPPER (mydata),
                                    UPPER (l_ap_station),
                                    l_wo_temp,
                                    UPPER (l_emp),
                                    res);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        res := 'OK SCRAPER ONLINE';

                        SELECT COUNT (1)
                          INTO L_COUNT
                          FROM MES4.R_FIXTURE_wip
                         WHERE     INSTR (UPPER (l_ap_station), LINE_NAME) >
                                   0
                               AND WORK_FLAG = '1';

                        IF L_COUNT > 1
                        THEN
                            DELETE FROM
                                mes4.r_ap_temp
                                  WHERE     data1 = 'SCADA-GW28'
                                        AND data2 = g_stationno;
                        END IF;
                    END IF;
                END IF;
            ELSE
                res := 'SCM-T03082';
            END IF;
        --------------------------------------------------------------------
        --------------------ACTION-M-SF-刮刀下線作業---------------------
        --------------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-SF'
        THEN                                            -------ADD    20110911
            IF l_this_input = 'SCRAPER SN'
            THEN
                OPEN check_scraper_exist;

                FETCH check_scraper_exist INTO l_tr_sn;

                IF check_scraper_exist%NOTFOUND
                THEN
                    res := 'SCM-T03424';
                ELSE
                    l_station :=
                        SUBSTR (l_ap_station, 0, LENGTH (l_ap_station) - 2);
                    l_station := l_station || 'P1';

                    SELECT data5
                      INTO l_emp
                      FROM mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data4 = 'EMP'
                           AND ROWNUM = 1;

                    check_scraper_offline (l_tr_sn,
                                           l_station,
                                           l_emp,
                                           res);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        z_scraper_offline_save (l_tr_sn,
                                                l_station,
                                                l_emp,
                                                res);

                        IF SUBSTR (res, 1, 2) = 'OK'
                        THEN
                            res := 'SCRAPER OFFLINE OK';

                            SELECT COUNT (1)
                              INTO L_COUNT
                              FROM MES4.R_FIXTURE_wip
                             WHERE     INSTR (UPPER (l_ap_station),
                                              LINE_NAME) >
                                       0
                                   AND WORK_FLAG = '1';

                            IF L_COUNT > 1
                            THEN
                                DELETE FROM
                                    mes4.r_ap_temp
                                      WHERE     data1 = 'SCADA-GW28'
                                            AND data2 = g_stationno;
                            END IF;
                        END IF;
                    END IF;
                END IF;

                CLOSE check_scraper_exist;
            ELSE
                res := 'SCM-T03082';
            END IF;
        ---------------------------------------------------------------
        ----------------ACTION-M-ST 钢网上線作業代碼---------------
        ---------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-ST'
        THEN
            IF l_this_input = 'TRAVEL SN WO'
            THEN
                SELECT COUNT (1)
                  INTO l_count
                  FROM mes4.r_station_wip
                 WHERE wo = mydata AND STATION = l_ap_station;

                IF l_count > 0
                THEN
                    l_next_input := 'STENCIL SN';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'TRAVEL SN WO',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK TRAVEL SN WO';
                ELSE
                    res := 'SCM-T03678:' || mydata;
                    RAISE l_exit;
                END IF;
            ELSIF l_this_input = 'STENCIL SN'
            THEN
                SELECT data5
                  INTO l_wo_temp
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'TRAVEL SN WO'
                       AND ROWNUM = 1;

                SELECT COUNT (1)
                  INTO L_COUNT
                  FROM MES4.R_STATION_WIP
                 WHERE STATION = l_ap_station AND ROWNUM = 1;

                IF L_COUNT > 0
                THEN
                    SELECT WO
                      INTO L_WO
                      FROM MES4.R_STATION_WIP
                     WHERE STATION = l_ap_station AND ROWNUM = 1;
                ELSE
                    res := 'SCM-T03397';
                    RAISE l_exit;
                END IF;

                L_LINE := SUBSTR (l_ap_station, 1, 5);
                --钢网上线前检查
                MES1.check_stencil ('STENCILCONTROL_ONLINECHECK',
                                    mydata,
                                    '',
                                    '',
                                    l_emp,
                                    L_LINE,
                                    l_ap_station,
                                    l_wo_temp,
                                    l_emp,
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    USER_CUSOR);

                FETCH USER_CUSOR INTO l_res;

                CLOSE USER_CUSOR;

                res := l_res;

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    res := res;
                    RAISE l_exit;
                END IF;

                --钢网上线
                MES1.check_stencil ('STENCILCONTROL_ONLINE2',
                                    mydata,
                                    '',
                                    '',
                                    l_emp,
                                    L_LINE,
                                    l_ap_station,
                                    l_wo_temp,
                                    l_emp,
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    '',
                                    USER_CUSOR);

                -- check_slotno (mydata, l_machine, res);

                FETCH USER_CUSOR INTO l_res;

                CLOSE USER_CUSOR;

                res := l_res;

                -- check_slotno (mydata, l_machine, res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    l_next_input := 'OK STENCIL ONLINE';
                ELSE
                    RAISE l_exit;
                END IF;
            ELSE
                res := 'SCM-T03082';
            END IF;
        --------------------------------------------------------------------
        --------------------ACTION-M-SN-钢网下線作業---------------------
        --------------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-SN'
        THEN                                            -------ADD    20110911
            IF l_this_input = 'STENCIL SN'
            THEN
                MES1.onoff_station_stencil ('',
                                            mydata,
                                            l_ap_station,
                                            l_emp,
                                            RES);

                IF SUBSTR (RES, 1, 2) <> 'OK'
                THEN
                    RAISE l_exit;
                END IF;
            ELSE
                res := 'SCM-T03551';
            END IF;
        ELSIF l_action_code = 'ACTION-M-SL'
        THEN
            IF l_this_input = 'MACHINE'
            THEN
                IF l_ap_station <> mydata
                THEN
                    res := 'MACHINE ERROR';
                    RAISE l_exit;
                END IF;


                L_NEXT_INPUT := 'TRAVEL SN WO';

                INSERT INTO MES4.R_AP_TEMP (DATA1,
                                            DATA2,
                                            DATA3,
                                            DATA4,
                                            DATA5,
                                            DATA6,
                                            DATA7,
                                            WORK_TIME)
                     VALUES ('SCADA-GW28',
                             G_STATIONNO,
                             TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                             'MACHINE',
                             MYDATA,
                             L_NEXT_INPUT,
                             '0',
                             SYSDATE);

                COMMIT;

                res := 'OK';
            ELSIF l_this_input = 'TRAVEL SN WO'
            THEN
                res := 'SCM-T03432:' || mydata;

                SELECT DATA5
                  INTO l_ap_station
                  FROM MES4.R_AP_TEMP
                 WHERE     DATA1 = 'SCADA-GW28'
                       AND DATA2 = G_STATIONNO
                       AND DATA4 = 'MACHINE'
                       AND ROWNUM = 1;

                SELECT COUNT (1)
                  INTO l_count
                  FROM mes4.r_wo_base
                 WHERE wo = MYDATA;

                IF l_count > 0
                THEN
                    SELECT p_no
                      INTO l_pno
                      FROM mes4.r_wo_base
                     WHERE wo = MYDATA AND ROWNUM = 1;
                ELSE
                    res := 'SCM-T03434:' || mydata;
                    RAISE l_exit;
                END IF;

                SELECT COUNT (1)
                  INTO l_count
                  FROM mes1.c_smt_ap_product  csap,
                       mes1.c_smt_ap_machine  csam,
                       mes1.c_smt_ap_list     csal
                 WHERE     csap.smt_code = csam.smt_code
                       AND csap.UNUSABLE_FLAG = csam.UNUSABLE_FLAG
                       AND csal.smt_code = csam.smt_code
                       AND csal.UNUSABLE_FLAG = csam.UNUSABLE_FLAG
                       AND csam.UNUSABLE_FLAG = 0
                       AND CSAL.PROCESS_FLAG = l_process
                       AND SUBSTR (CSAM.MACHINE_SN, 1, 5) =
                           SUBSTR (l_ap_station, 1, 5)
                       AND csap.p_no = l_pno;


                IF l_count > 0
                THEN
                    L_NEXT_INPUT := 'TR SN';


                    INSERT INTO MES4.R_AP_TEMP (DATA1,
                                                DATA2,
                                                DATA3,
                                                DATA4,
                                                DATA5,
                                                DATA6,
                                                DATA7,
                                                WORK_TIME)
                         VALUES ('SCADA-GW28',
                                 G_STATIONNO,
                                 TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                                 'TRAVEL SN WO',
                                 MYDATA,
                                 L_NEXT_INPUT,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                ELSE
                    res :=
                           'SCM-T03420:'
                        || l_pno
                        || ','
                        || l_ap_station
                        || ','
                        || l_process;
                    RAISE l_exit;
                END IF;

                res := 'OK TRAVEL SN WO';
            ELSIF l_this_input = 'TR SN'
            THEN
                SELECT DATA5
                  INTO l_ap_station
                  FROM MES4.R_AP_TEMP
                 WHERE     DATA1 = 'SCADA-GW28'
                       AND DATA2 = G_STATIONNO
                       AND DATA4 = 'MACHINE'
                       AND ROWNUM = 1;

                SELECT DATA5
                  INTO l_wo
                  FROM MES4.R_AP_TEMP
                 WHERE     DATA1 = 'SCADA-GW28'
                       AND DATA2 = G_STATIONNO
                       AND DATA4 = 'TRAVEL SN WO'
                       AND ROWNUM = 1;

                SELECT p_no
                  INTO l_pno
                  FROM mes4.r_wo_base
                 WHERE wo = l_wo AND ROWNUM = 1;

                res := 'SCM-T03379:' || mydata;

                SELECT mes1.get_scan_sn (mydata) INTO g_tr_sn FROM DUAL;

                SELECT COUNT (1)
                  INTO l_count
                  FROM mes4.r_tr_sn
                 WHERE tr_sn = g_tr_sn;

                IF l_count > 0
                THEN
                    SELECT cust_kp_no
                      INTO l_kpno
                      FROM mes4.r_tr_sn
                     WHERE tr_sn = g_tr_sn;

                    SELECT COUNT (1)
                      INTO l_count
                      FROM mes4.r_tr_sn_wip
                     WHERE tr_sn = g_tr_sn;

                    IF l_count > 0
                    THEN
                        SELECT MES1.GET_SLOTBY_SANSN (l_ap_station,
                                                      l_kpno,
                                                      l_pno,
                                                      l_process)
                          INTO l_res
                          FROM DUAL;

                        IF LENGTH (l_res) > 0
                        THEN
                            RES := 'OK ' || l_res;
                        ELSE
                            res := 'SCM-T03435:' || l_pno || ',' || l_kpno;
                            RAISE l_exit;
                        END IF;
                    ELSE
                        res := 'SCM-T03411';
                        RAISE l_exit;
                    END IF;
                ELSE
                    res := 'SCM-T03404';
                    RAISE l_exit;
                END IF;
            ELSE
                res := 'SCM-T03082';
            END IF;
        ------------------  ACTION-M-SA 錫膏添加作業-----------------------
        -------------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-SA'
        THEN                                 --------------ADD BY DZL 20101123
            IF l_this_input = 'TR SN'
            THEN
                l_ap_station :=
                    SUBSTR (l_ap_station, 0, LENGTH (l_ap_station) - 2);
                l_ap_station := l_ap_station || 'P1';

                SELECT COUNT (a.tr_sn)
                  INTO l_count
                  FROM mes4.r_tr_sn_wip a, mes4.r_solder_detail b
                 WHERE     a.tr_sn = b.tr_sn
                       AND a.work_flag = '1'
                       AND b.work_flag = '5'
                       AND a.station = l_ap_station;

                IF l_count = 0
                THEN
                    res := 'SCM-T03436';
                ELSE
                    SELECT a.tr_sn
                      INTO l_tr_sn
                      FROM mes4.r_tr_sn_wip a, mes4.r_solder_detail b
                     WHERE     a.tr_sn = b.tr_sn
                           AND a.work_flag = '1'
                           AND b.work_flag = '5'
                           AND a.station = l_ap_station
                           AND ROWNUM = 1;

                    IF l_tr_sn = mydata
                    THEN
                        UPDATE mes4.r_solder_detail
                           SET last_append_time = SYSDATE
                         WHERE tr_sn = l_tr_sn;

                        ------INSER 添加記錄
                        INSERT INTO mes4.r_tr_sn_detail (tr_sn,
                                                         cust_kp_no,
                                                         mfr_kp_no,
                                                         mfr_code,
                                                         date_code,
                                                         lot_code,
                                                         qty,
                                                         ext_qty,
                                                         location_flag,
                                                         work_flag,
                                                         wo,
                                                         station,
                                                         work_time,
                                                         emp_no)
                            SELECT *
                              FROM (  SELECT tr_sn,
                                             kp_no,
                                             mfr_kp_no,
                                             mfr_code,
                                             date_code,
                                             lot_code,
                                             add_qty,
                                             add_qty     ext_qty,
                                             '2',
                                             '3',
                                             wo,
                                             station,
                                             SYSDATE,
                                             emp_no
                                        FROM mes4.r_kp_list
                                       WHERE 1 = 1 AND tr_sn = l_tr_sn
                                    ORDER BY start_time DESC)
                             WHERE ROWNUM = 1;

                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno;

                        COMMIT;
                        res := 'OK SOLDER APPEND';
                    ELSE
                        res := 'SCM-T03415:' || l_tr_sn;
                    END IF;
                END IF;
            ELSE
                res := 'SCM-T03082';
            END IF;
        --------------------------------------------------------------------
        ------------------  ACTION-M-SB 錫膏上料作業？----------------------
        --------------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-SB'
        THEN                                        -------ADD BY DZL 20101123
            IF l_this_input = 'TRAVEL SN WO'    -------BY DZL 20101123 不掃錫膏流程卡
            THEN
                OPEN check_solder_travel_sn;

                FETCH check_solder_travel_sn INTO l_wo;

                IF check_solder_travel_sn%NOTFOUND
                THEN
                    res := 'NO TRAVEL SN WO';
                ELSE
                    OPEN check_solder_travel_station;

                    FETCH check_solder_travel_station INTO l_wo;

                    IF check_solder_travel_station%NOTFOUND
                    THEN
                        res := 'TRAVEL SN IS NOT MATCH MACHINE';
                    ELSE
                        SELECT work_flag
                          INTO l_wo_work_flag
                          FROM mes4.r_wo_base
                         WHERE wo = UPPER (l_wo);

                        IF l_wo_work_flag = '0'
                        THEN
                            res := 'SCHEDULE WO';
                        ELSIF l_wo_work_flag = '2'
                        THEN
                            res := 'CLOSED WO';
                        ELSIF l_wo_work_flag = '1'
                        THEN
                            res := 'OK TRAVEL SN';
                            --L_NEXT_INPUT := 'PROCESS';
                            l_next_input := 'TR SN';

                            INSERT INTO mes4.r_ap_temp (data1,
                                                        data2,
                                                        data3,
                                                        data4,
                                                        data5,
                                                        data6,
                                                        data7,
                                                        work_time)
                                     VALUES (
                                                'SCADA-GW28',
                                                g_stationno,
                                                TO_CHAR (
                                                      TO_NUMBER (l_sequence)
                                                    + 1),
                                                'TRAVEL SN WO',
                                                mydata,
                                                l_next_input,
                                                '0',
                                                SYSDATE);
                        ELSE
                            res := 'SCM-T03082';
                        END IF;
                    END IF;

                    CLOSE check_solder_travel_station;
                END IF;

                CLOSE check_solder_travel_sn;

                COMMIT;
            /*
            ELSIF L_THIS_INPUT = 'PROCESS'
            THEN
              IF    UPPER (MYDATA) = 'T'
                 OR UPPER (MYDATA) = 'B'
                 OR UPPER (MYDATA) = 'D'
              THEN
                 RES := 'OK PROCESS';
                 L_NEXT_INPUT := 'TR SN';

                 INSERT INTO MES4.R_AP_TEMP
                             (DATA1, DATA2,
                              DATA3,
                              DATA4, DATA5, DATA6, DATA7, WORK_TIME
                             )
                      VALUES ('SCADA-GW28', G_STATIONNO,
                              TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                              'PROCESS', MYDATA, L_NEXT_INPUT, '0', SYSDATE
                             );
              ELSE
                 RES := 'INVALID PROCESS';
              END IF;
            */
            ELSIF l_this_input = 'TR SN'
            THEN
                /*
                   SELECT DATA5
                    INTO L_TRAVEL_SN
                    FROM MES4.R_AP_TEMP
                   WHERE DATA1 = 'SCADA-GW28'
                     AND DATA2 = G_STATIONNO
                     AND DATA4 = 'TRAVEL SN'
                     AND ROWNUM = 1;

                   SELECT WO
                    INTO L_WO
                    FROM MES4.R_TRAVEL_SN
                   WHERE TRAVEL_SN = L_TRAVEL_SN;

                --------------------------ADD SCAN FIXTURE ON/OFF LINE CODE  EDIT BY HALTON 20090318 BEGIN--------------------------
                    OPEN CHECK_LINE_CONTROL;

                    FETCH CHECK_LINE_CONTROL
                    INTO L_STATION_NAME;

                       IF CHECK_LINE_CONTROL%FOUND
                       THEN
                         OPEN CHECK_FIXTURE_ONLINE;
                                FETCH CHECK_FIXTURE_ONLINE
                         INTO L_WO_WIP;
                               IF CHECK_FIXTURE_ONLINE%NOTFOUND
                               THEN
                                  RES:='治具末被掃描上線﹐請先掃描治具上線﹗';

                                  DELETE FROM MES4.R_AP_TEMP
                                  WHERE DATA1 = 'SCADA-GW28' AND DATA2 = G_STATIONNO;

                                  COMMIT;

                                  CLOSE CHECK_FIXTURE_ONLINE;
                                  RAISE L_EXIT;
                               ELSE

                                    IF L_WO<>L_WO_WIP
                                    THEN
                                      RES:='治具所對應工單' || L_WO_WIP || '與在線工單' || L_WO || '不一至﹐請將上一工單對應治具先掃描下線﹗';

                                      DELETE FROM MES4.R_AP_TEMP
                                         WHERE DATA1 = 'SCADA-GW28' AND DATA2 = G_STATIONNO;
                                      COMMIT;

                                      CLOSE CHECK_FIXTURE_ONLINE;
                                      RAISE L_EXIT;
                                    END IF;
                               END IF;
                       CLOSE CHECK_FIXTURE_ONLINE;
                       END IF;
                       CLOSE CHECK_LINE_CONTROL;
                --------------------------ADD SCAN FIXTURE ON/OFF LINE CODE  EDIT BY HALTON 20090318 END--------------------------
       */
                l_ap_station :=
                    SUBSTR (l_ap_station, 0, LENGTH (l_ap_station) - 2);
                l_ap_station := l_ap_station || 'P1';

                OPEN check_solderwip;

                FETCH check_solderwip INTO l_tr_sn_temp;

                IF check_solderwip%FOUND
                THEN                                       ------CHECK STATION
                    res := 'SCM-T03405';

                    CLOSE check_solderwip;
                ELSE
                    CLOSE check_solderwip;

                    OPEN check_solder_in_station;

                    FETCH check_solder_in_station INTO l_tr_sn, l_wo;

                    IF check_solder_in_station%NOTFOUND
                    THEN                                   ------CHECK STATION
                        res := 'SCM-T03406';

                        CLOSE check_solder_in_station;
                    ELSE
                        CLOSE check_solder_in_station;

                        check_solder (UPPER (mydata),
                                      UPPER (l_ap_station),
                                      res);
                    END IF;
                END IF;

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    l_next_input := 'END';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'TR SN',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);
                END IF;
            ELSIF UPPER (l_this_input) = 'END'
            THEN
                IF UPPER (mydata) = 'END'
                THEN
                    SELECT data5
                      INTO l_tr_sn
                      FROM mes4.r_ap_temp
                     WHERE data2 = g_stationno AND data4 = 'TR SN';

                    SELECT data5
                      INTO l_emp
                      FROM mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data4 = 'EMP'
                           AND ROWNUM = 1;

                    l_ap_station :=
                        SUBSTR (l_ap_station, 0, LENGTH (l_ap_station) - 2);
                    l_ap_station := l_ap_station || 'P1';

                    SELECT wo
                      INTO l_wo
                      FROM mes4.r_tr_sn_wip
                     WHERE tr_sn = l_tr_sn;

                    z_solder_save (UPPER (l_ap_station),
                                   UPPER (l_tr_sn),
                                   UPPER (l_wo),
                                   UPPER (l_emp),
                                   res);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        res := 'OK SOLDER ONLINE';

                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno;
                    END IF;
                ELSE
                    res := 'ERR END';
                END IF;
            ELSE
                res := 'SCM-T03082';
            END IF;
        --------------------------------------------------------------------
        ------------------  ACTION-M-SC 錫膏非空瓶下料作業------------------
        --------------------------------------------------------------------

        ----ADDED BY James Tang 20101209
        ELSIF l_action_code = 'ACTION-M-SE'
        THEN
            IF l_this_input = 'TR SN'
            THEN
                l_ap_station :=
                    SUBSTR (l_ap_station, 0, LENGTH (l_ap_station) - 2);
                l_ap_station := l_ap_station || 'P1';

                OPEN check_solderwip;

                FETCH check_solderwip INTO l_tr_sn_temp;

                IF check_solderwip%FOUND
                THEN                                       ------CHECK STATION
                    res := 'SCM-T03405';

                    CLOSE check_solderwip;
                ELSE
                    CLOSE check_solderwip;

                    OPEN check_solder_double_in_station;

                    FETCH check_solder_double_in_station
                        INTO l_tr_sn, l_old_wo;

                    IF check_solder_double_in_station%FOUND
                    THEN                                   ------CHECK STATION
                        res := 'SCM-T03405';

                        CLOSE check_solder_double_in_station;
                    ELSE
                        CLOSE check_solder_double_in_station;

                        res := 'OK,TR SN';
                    END IF;

                    check_solder (UPPER (mydata), UPPER (l_ap_station), res);
                END IF;

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    l_next_input := 'NEW WO';

                    --INSERT INTO mes4.r_ap_temp
                    -- (data1, data2,
                    -- data3, data4,
                    --data5, data6, data7, work_time
                    -- )
                    --VALUES ('SCADA-GW28', g_stationno,
                    --TO_CHAR (TO_NUMBER (l_sequence) + 1), 'TR SN',
                    --mydata, l_next_input, '0', SYSDATE
                    -- );
                    UPDATE mes4.r_ap_temp
                       SET work_time = SYSDATE,
                           data6 = l_next_input,
                           data9 = mydata
                     WHERE     data2 = g_stationno
                           AND data1 = 'SCADA-GW28'
                           AND data5 = 'ACTION-M-SE';
                END IF;
            ELSIF l_this_input = 'NEW WO'
            THEN
                IF LENGTH (mydata) != 12 OR UPPER (mydata) NOT LIKE '0000%'
                THEN
                    res := 'INVALID WO';
                ELSE
                    l_new_wo := UPPER (mydata);

                    -- RES :='UPDATE THE NEW WO ERROR';
                    -- update mes4.r_tr_sn_wip set wo=l_new_wo  where tr_sn=l_tr_sn;
                    OPEN get_solder_tr_sn_new_wo;

                    FETCH get_solder_tr_sn_new_wo INTO l_tr_sn, l_new_wo1;

                    IF get_solder_tr_sn_new_wo%NOTFOUND
                    THEN
                        res := 'SCM-T03082';

                        CLOSE get_solder_tr_sn_new_wo;
                    ELSE
                        CLOSE get_solder_tr_sn_new_wo;
                    END IF;

                    --check_solder (l_tr_sn, UPPER (l_ap_station), res);
                    OPEN check_solder_version;

                    FETCH check_solder_version INTO l_p_version;

                    IF check_solder_version%FOUND
                    THEN
                        res := 'OK,SOLDER MATCH WO';

                        CLOSE check_solder_version;
                    ELSE
                        res := 'SCM-T03429';

                        CLOSE check_solder_version;
                    END IF;
                END IF;

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    l_next_input := 'END';
                    res := 'OK,NEW WO';

                    --INSERT INTO mes4.r_ap_temp
                    -- (data1, data2,
                    -- data3, data4,
                    -- data5, data6, data7, work_time
                    --  )
                    --VALUES ('SCADA-GW28', g_stationno,
                    --TO_CHAR (TO_NUMBER (l_sequence) + 1), 'NEW WO',
                    -- mydata, l_next_input, '0', SYSDATE
                    -- );
                    UPDATE mes4.r_ap_temp
                       SET work_time = SYSDATE,
                           data6 = l_next_input,
                           data10 = mydata
                     WHERE     data2 = g_stationno
                           AND data1 = 'SCADA-GW28'
                           AND data5 = 'ACTION-M-SE';
                END IF;
            ELSIF UPPER (l_this_input) = 'END'
            THEN
                IF UPPER (mydata) = 'END'
                THEN
                    l_ap_station :=
                        SUBSTR (l_ap_station, 0, LENGTH (l_ap_station) - 2);
                    l_ap_station := l_ap_station || 'P1';

                    OPEN get_solder_tr_sn_new_wo;

                    FETCH get_solder_tr_sn_new_wo INTO l_tr_sn, l_new_wo;

                    IF get_solder_tr_sn_new_wo%NOTFOUND
                    THEN
                        res := 'SCM-T03082';

                        CLOSE get_solder_tr_sn_new_wo;
                    ELSE
                        CLOSE get_solder_tr_sn_new_wo;
                    END IF;

                    res := 'SCM-T03082';

                    UPDATE mes4.r_tr_sn_wip
                       SET wo = l_new_wo, station = l_ap_station
                     WHERE tr_sn = l_tr_sn;

                    res := 'OK,UPDATE SOLDER DATA';

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        res := 'OK SOLDER TRANSFERRED';

                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno;
                    END IF;
                ELSE
                    res := 'ERR END';
                END IF;
            ELSE
                res := 'SCM-T03082';
            END IF;
        ELSIF l_action_code = 'ACTION-M-SC'
        THEN                                        -------ADD BY DZL 20101123
            IF l_this_input = 'TR SN'
            THEN
                l_tr_sn := mydata;

                OPEN check_trsn_status;

                FETCH check_trsn_status INTO l_tr_sn;

                IF check_trsn_status%NOTFOUND
                THEN
                    res := 'SCM-T03424';
                ELSE
                    OPEN check_trsn_solder;

                    FETCH check_trsn_solder INTO l_tr_sn;

                    IF check_trsn_solder%NOTFOUND
                    THEN
                        res := 'SCM-T03424';
                    ELSE
                        l_tr_sn := mydata;
                        /*
                        OPEN GET_SOLDER_STATION;

                        FETCH GET_SOLDER_STATION
                         INTO L_STATION;

                        IF GET_SOLDER_STATION%NOTFOUND
                        THEN
                           RES := 'TR_SN_WIP DATA ERROR';
                        ELSE
                   */
                        l_station :=
                            SUBSTR (l_ap_station,
                                    0,
                                    LENGTH (l_ap_station) - 2);
                        l_station := l_station || 'P1';
                        check_solder_offline (l_station, mydata, res);

                        IF SUBSTR (res, 1, 2) = 'OK'
                        THEN
                            l_next_input := 'END';

                            INSERT INTO mes4.r_ap_temp (data1,
                                                        data2,
                                                        data3,
                                                        data4,
                                                        data5,
                                                        data6,
                                                        data7,
                                                        work_time)
                                     VALUES (
                                                'SCADA-GW28',
                                                g_stationno,
                                                TO_CHAR (
                                                      TO_NUMBER (l_sequence)
                                                    + 1),
                                                'TR SN',
                                                mydata,
                                                l_next_input,
                                                '0',
                                                SYSDATE);
                        END IF;
                    --END IF;

                    --CLOSE GET_SOLDER_STATION;
                    END IF;

                    CLOSE check_trsn_solder;
                END IF;

                CLOSE check_trsn_status;
            ELSIF l_this_input = 'END'
            THEN
                IF UPPER (mydata) = 'END'
                THEN
                    SELECT data5
                      INTO l_tr_sn
                      FROM mes4.r_ap_temp
                     WHERE data2 = g_stationno AND data4 = 'TR SN';

                    /*
                OPEN GET_SOLDER_STATION;

                    FETCH GET_SOLDER_STATION
                     INTO L_STATION;

                    IF GET_SOLDER_STATION%NOTFOUND
                    THEN
                       RES := 'TR_SN_WIP DATA ERROR';
                    ELSE
                */
                    l_station :=
                        SUBSTR (l_ap_station, 0, LENGTH (l_ap_station) - 2);
                    l_station := l_station || 'P1';
                    z_solder_save_notnull (l_station, l_tr_sn, res);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        res := 'OK SAVE NOT NULL';

                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno;
                    END IF;
                --END IF;

                --CLOSE GET_SOLDER_STATION;
                ELSE
                    res := 'ERR END';
                END IF;
            ELSE
                res := 'SCM-T03082';
            END IF;
        --------------------------------------------------------------------
        ------------------  ACTION-M-SD錫膏空瓶下料作業  -------------------
        --------------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-SD'
        THEN                                        -------ADD BY DZL 20101123
            IF l_this_input = 'TR SN'
            THEN
                OPEN check_trsn_status;

                FETCH check_trsn_status INTO l_tr_sn;

                IF check_trsn_status%NOTFOUND
                THEN
                    res := 'SCM-T03424';
                ELSE
                    OPEN check_trsn_solder;

                    FETCH check_trsn_solder INTO l_tr_sn;

                    IF check_trsn_solder%NOTFOUND
                    THEN
                        res := 'SCM-T03424';
                    ELSE
                        l_tr_sn := mydata;
                        /*
                   OPEN GET_SOLDER_STATION;

                        FETCH GET_SOLDER_STATION
                         INTO L_STATION;

                        IF GET_SOLDER_STATION%NOTFOUND
                        THEN
                           RES := 'TR_SN_WIP DATA ERROR';
                        ELSE
                   */
                        l_station :=
                            SUBSTR (l_ap_station,
                                    0,
                                    LENGTH (l_ap_station) - 2);
                        l_station := l_station || 'P1';
                        check_solder_offline (l_station, mydata, res);

                        IF SUBSTR (res, 1, 2) = 'OK'
                        THEN
                            l_next_input := 'END';

                            INSERT INTO mes4.r_ap_temp (data1,
                                                        data2,
                                                        data3,
                                                        data4,
                                                        data5,
                                                        data6,
                                                        data7,
                                                        work_time)
                                     VALUES (
                                                'SCADA-GW28',
                                                g_stationno,
                                                TO_CHAR (
                                                      TO_NUMBER (l_sequence)
                                                    + 1),
                                                'TR SN',
                                                mydata,
                                                l_next_input,
                                                '0',
                                                SYSDATE);
                        END IF;
                    --END IF;

                    --CLOSE GET_SOLDER_STATION;
                    END IF;

                    CLOSE check_trsn_solder;
                END IF;

                CLOSE check_trsn_status;
            ELSIF l_this_input = 'END'
            THEN
                IF UPPER (mydata) = 'END'
                THEN
                    SELECT data5
                      INTO l_tr_sn
                      FROM mes4.r_ap_temp
                     WHERE data2 = g_stationno AND data4 = 'TR SN';

                    z_solder_save_null (l_tr_sn, res);

                    IF SUBSTR (res, 1, 2) = 'OK'
                    THEN
                        res := 'OK SAVE NULL';

                        DELETE FROM
                            mes4.r_ap_temp
                              WHERE     data1 = 'SCADA-GW28'
                                    AND data2 = g_stationno;
                    END IF;
                ELSE
                    res := 'ERR END';
                END IF;
            ELSE
                res := 'SCM-T03082';
            END IF;
        ---------------------------------------------------------------
        ------------------  ACTION-M-K用于在線核對  -------------------
        ---------------------------------------------------------------

        ---------------------------------------------------------------
        ------------------  ACTION-M-K用于在線核對  -----------------
        ---------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-K'
        THEN
            IF l_this_input = 'MACHINE'
            THEN
                IF l_ap_station <> mydata
                THEN
                    res := 'MACHINE ERROR';
                    RAISE l_exit;
                END IF;

                ------CHECK SETUP SHEET-------
                SELECT station
                  INTO l_temp_machine
                  FROM mes4.r_station_wip
                 WHERE station = mydata AND ROWNUM = 1;

                IF l_temp_machine = ''
                THEN
                    res := 'NOT SETUP SHEET';
                    RAISE l_exit;
                ELSE
                    ------CHECK WHETHER KP IS FULL-------
                    SELECT COUNT (*)
                      INTO tmp_tmp
                      FROM mes4.r_station_wip
                     WHERE     station = mydata
                           AND tr_sn IS NULL
                           AND feeder_type <> 'TRAY';

                    IF tmp_tmp > 0
                    THEN
                        res := 'SCM-T03421';
                        RAISE l_exit;
                    ELSE
                        SELECT COUNT (*)
                          INTO tmp_tmp
                          FROM (SELECT DISTINCT kp_no
                                  FROM mes4.r_station_wip
                                 WHERE     station = mydata
                                       AND feeder_type = 'TRAY'
                                       AND standard_qty <> 0
                                MINUS
                                SELECT DISTINCT kp_no
                                  FROM mes4.r_station_wip
                                 WHERE     station = mydata
                                       AND tr_sn IS NOT NULL
                                       AND feeder_type = 'TRAY');

                        IF tmp_tmp > 0
                        THEN
                            res := 'SCM-T03421';
                            RAISE l_exit;
                        END IF;
                    END IF;

                    l_next_input := 'SLOT NO';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'MACHINE',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    DELETE mes4.r_station_temp
                     WHERE station = mydata AND travel_sn = 'WIP_CONTROL';

                    --清空不必要的歷史記錄...
                    COMMIT;
                    res := 'OK MACHINE';
                END IF;
            ELSIF l_this_input = 'SLOT NO'
            THEN
                SELECT data5
                  INTO l_machine
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'MACHINE'
                       AND ROWNUM = 1;

                --IF END IS WANNA...
                IF mydata = 'END'
                THEN
                    res := 'CHECK END';

                    SELECT COUNT (*)
                      INTO tmp_tmp
                      FROM (SELECT slot_no
                              FROM mes4.r_station_wip
                             WHERE station = l_machine AND standard_qty <> 0
                            MINUS
                            SELECT slot_no
                              FROM mes4.r_station_temp
                             WHERE station = l_machine);

                    IF tmp_tmp <> 0
                    THEN
                        SELECT slot_no
                          INTO l_temp_slot
                          FROM (SELECT slot_no
                                  FROM mes4.r_station_wip
                                 WHERE     station = l_machine
                                       AND tr_sn IS NOT NULL
                                MINUS
                                SELECT slot_no
                                  FROM mes4.r_station_temp
                                 WHERE     station = l_machine
                                       AND tr_sn IS NOT NULL)
                         WHERE ROWNUM = 1;

                        res := 'SCM-T03259:' || l_temp_slot;
                        RAISE l_exit;
                    ELSE
                        res := 'CHECK OK';

                        INSERT INTO mes4.r_job_record
                             VALUES ('CHECK_WIP_KP',
                                     l_machine,
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     SYSDATE);

                        COMMIT;

                        DELETE mes4.r_ap_temp
                         WHERE data1 = 'SCADA-GW28' AND data2 = g_stationno;

                        COMMIT;

                        DELETE mes4.r_station_temp
                         WHERE     station = l_machine
                               AND travel_sn = 'WIP_CONTROL';

                        COMMIT;
                        res := 'OK SLOT NO';
                        RAISE l_exit;
                    END IF;
                END IF;

                ----------CHECK SLOT_NO------------'
                SELECT COUNT (slot_no)
                  INTO tmp_tmp
                  FROM mes4.r_station_wip
                 WHERE     station = l_machine
                       AND slot_no = mydata
                       AND ROWNUM = 1;

                IF tmp_tmp <> 1
                THEN
                    res := 'NO SLOT NO';
                    RAISE l_exit;
                ELSE
                    ----CHECK WHETHER DUP KP-----
                    SELECT COUNT (*)
                      INTO tmp_tmp
                      FROM mes4.r_station_temp
                     WHERE station = l_machine AND slot_no = mydata;

                    IF tmp_tmp > 0
                    THEN
                        res := 'SCM-T03409';
                        RAISE l_exit;
                    END IF;

                    l_next_input := 'TR SN';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'SLOT NO',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK SLOT NO';
                END IF;
            ELSIF l_this_input = 'TR SN'
            THEN
                res := 'SCM-T03379:' || mydata;

                SELECT mes1.get_scan_sn (mydata) INTO g_tr_sn FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    --res := '料盘序号不存在 10,仓库未发料' || mydata;
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                SELECT data5
                  INTO l_machine
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'MACHINE'
                       AND ROWNUM = 1;

                SELECT data5
                  INTO l_slot
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'SLOT NO'
                       AND ROWNUM = 1;

                SELECT COUNT (*)
                  INTO tmp_tmp
                  FROM mes4.r_station_wip
                 WHERE     station = l_machine
                       AND slot_no = l_slot
                       AND feeder_type = 'TRAY';

                IF tmp_tmp = 0
                THEN                                         --說明不是一個TRAY盤料...
                    SELECT NVL (tr_sn, '-')
                      INTO l_temp_trsn
                      FROM mes4.r_station_wip
                     WHERE     station = l_machine
                           AND slot_no = l_slot
                           AND ROWNUM = 1;

                    IF l_temp_trsn <> g_tr_sn
                    THEN
                        res := 'SCM-T03410:' || l_temp_trsn || ',' || g_tr_sn;
                        RAISE l_exit;
                    ELSE
                        res := 'OK TR SN';

                        SELECT data5
                          INTO l_emp
                          FROM mes4.r_ap_temp
                         WHERE     data1 = 'SCADA-GW28'
                               AND data2 = g_stationno
                               AND data3 = '1'
                               AND data4 = 'EMP';

                        INSERT INTO mes4.r_station_temp (travel_sn,
                                                         smt_code,
                                                         station,
                                                         station_flag,
                                                         wo,
                                                         p_no,
                                                         p_version,
                                                         tr_sn,
                                                         slot_no,
                                                         kp_no,
                                                         feeder_type,
                                                         feeder_no,
                                                         standard_qty,
                                                         shortage_flag,
                                                         shareslot_flag,
                                                         process_flag,
                                                         replacekp_flag,
                                                         work_time,
                                                         emp_no,
                                                         wip_use_flag)
                            (SELECT 'WIP_CONTROL',
                                    smt_code,
                                    station,
                                    station_flag,
                                    wo,
                                    p_no,               --SUBSTR(TR_CODE,1,16)
                                    p_version,
                                    tr_sn,
                                    slot_no,
                                    kp_no,
                                    feeder_type,
                                    feeder_no,
                                    standard_qty,
                                    shortage_flag,
                                    shareslot_flag,
                                    process_flag,
                                    replacekp_flag,
                                    SYSDATE,
                                    l_emp,
                                    '1'                            ----wangyan
                               FROM mes4.r_station_wip
                              WHERE station = l_machine AND slot_no = l_slot);
                    END IF;

                    DELETE mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data3 NOT IN ('0',
                                             '1',
                                             '2',
                                             '3');

                    COMMIT;
                ELSIF tmp_tmp > 0
                THEN                                         --對于是TRAY盤料的情況的分析
                    SELECT tr_sn
                      INTO l_temp_trsn
                      FROM mes4.r_station_wip
                     WHERE     station = l_machine
                           AND kp_no IN
                                   (SELECT kp_no
                                      FROM mes4.r_station_wip
                                     WHERE     station = l_machine
                                           AND slot_no = l_slot)
                           AND tr_sn IS NOT NULL
                           AND ROWNUM = 1;

                    IF l_temp_trsn <> g_tr_sn
                    THEN
                        res := 'SCM-T03410:' || l_temp_trsn || ',' || g_tr_sn;
                        RAISE l_exit;
                    ELSE
                        SELECT data5
                          INTO l_emp
                          FROM mes4.r_ap_temp
                         WHERE     data1 = 'SCADA-GW28'
                               AND data2 = g_stationno
                               AND data3 = '1'
                               AND data4 = 'EMP';

                        INSERT INTO mes4.r_station_temp (travel_sn,
                                                         smt_code,
                                                         station,
                                                         station_flag,
                                                         wo,
                                                         p_no,
                                                         p_version,
                                                         tr_sn,
                                                         slot_no,
                                                         kp_no,
                                                         feeder_type,
                                                         feeder_no,
                                                         standard_qty,
                                                         shortage_flag,
                                                         shareslot_flag,
                                                         process_flag,
                                                         replacekp_flag,
                                                         work_time,
                                                         emp_no,
                                                         wip_use_flag)
                            (SELECT 'WIP_CONTROL',
                                    smt_code,
                                    station,
                                    station_flag,
                                    wo,
                                    p_no,               --SUBSTR(TR_CODE,1,16)
                                    p_version,
                                    tr_sn,
                                    slot_no,
                                    kp_no,
                                    feeder_type,
                                    feeder_no,
                                    standard_qty,
                                    shortage_flag,
                                    shareslot_flag,
                                    process_flag,
                                    replacekp_flag,
                                    SYSDATE,
                                    l_emp,
                                    '1'                             ---wangyan
                               FROM mes4.r_station_wip
                              WHERE     station = l_machine
                                    AND kp_no IN
                                            (SELECT kp_no
                                               FROM mes4.r_station_wip
                                              WHERE     station = l_machine
                                                    AND slot_no = l_slot));
                    END IF;

                    DELETE mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data3 NOT IN ('0', '1', '2');

                    COMMIT;
                END IF;

                res := 'OK TR SN';
            --L_NEXT_INPUT := 'SLOT/END';
            --INSERT INTO MES4.R_AP_TEMP
            --             (DATA1, DATA2,
            --              DATA3,
            --              DATA4, DATA5, DATA6, DATA7, WORK_TIME
            --             )
            --      VALUES ('SCADA-GW28', G_STATIONNO,
            --              TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
            --              'SLOT NO', MYDATA, L_NEXT_INPUT, '0', SYSDATE
            --             );
            -- COMMIT;
            --come on---
            --------CHECK ONLINE TR_SN-----------'
            END IF;
        ---------------------------------------------------------------
        ------------------ ACTION-M-P用于Kitting備料 ----------------
        ---------------------------------------------------------------
        ELSIF l_action_code = 'ACTION-M-P'
        THEN
            --處理方法﹕
            --主要是征對MES4.R_STATION_WIP作相應的處理
            res := 'KITTING PREPARE';

            IF l_this_input = 'TR SN'
            THEN
                res := 'KITTING PROMPT';
                res := 'OK';

                ------CHECK SETUP SHEET-------
                SELECT station
                  INTO l_temp_machine
                  FROM mes4.r_station_wip
                 WHERE station = l_ap_station AND ROWNUM = 1;

                IF l_temp_machine = ''
                THEN
                    res := 'NOT SETUP SHEET';
                    RAISE l_exit;
                ELSE
                    SELECT COUNT (*)
                      INTO tmp_tmp
                      FROM mes4.r_station_wip
                     WHERE station = l_ap_station AND tr_sn = mydata;

                    IF tmp_tmp <> 1
                    THEN
                        res :=
                            'THIS TR_SN:' || mydata || ' NO RECORD IN WIP...';
                        RAISE l_exit;
                    ELSE
                        SELECT COUNT (*)
                          INTO tmp_tmp
                          FROM mes4.r_station_wip
                         WHERE     station = l_ap_station
                               AND tr_sn = mydata
                               AND SUBSTR (emp_no, 1, 1) = '+';

                        IF tmp_tmp = 0
                        THEN
                            SELECT COUNT (*)
                              INTO tmp_tmp
                              FROM mes1.c_program_parameter
                             WHERE     program_type = 'SP'
                                   AND program_name = 'G_MACHINE_SP_WORKTYPE'
                                   AND function_name = 'ACTION-M-P'
                                   AND function_object = 'CHECK_ONLY_1'
                                   AND function_value1 = 'Y';

                            IF tmp_tmp > 0
                            THEN
                                l_temp_slot_cm_all := NULL;
                                l_temp_trsn_cm_all := NULL;

                                /* --------------------------------如果某機台只要有任何一軌叫過料﹐則此機台不允許再叫料(不包括泛用機)。---------------------*/
                                OPEN call_material04;

                                LOOP
                                    FETCH call_material04 INTO l_temp_slot_cm;

                                    EXIT WHEN call_material04%NOTFOUND;
                                    l_temp_slot_cm_all :=
                                           l_temp_slot_cm_all
                                        || l_temp_slot_cm
                                        || ',';
                                END LOOP;

                                CLOSE call_material04;

                                SELECT   LENGTH (l_temp_slot_cm_all)
                                       - LENGTH (
                                             REPLACE (l_temp_slot_cm_all,
                                                      ',',
                                                      ''))
                                  INTO tmp_tmp
                                  FROM DUAL;

                                --  IF l_temp_slot_cm <> '' OR l_temp_slot_cm IS NOT NULL
                                IF tmp_tmp >= '2'
                                THEN
                                    res := l_temp_slot_cm_all || ' HAVE SCAN';
                                    RAISE l_exit;
                                END IF;

                                /* --------------------------------如果某機台只要有任何一軌叫過料﹐則此機台不允許再叫料(不包括泛用機)。---------------------*/

                                /* --------------------------------如果某機台線邊只要有一盤物料未掃上線﹐則此機台不允許再叫料(不包括泛用機)。---------------------*/
                                OPEN call_material03;

                                LOOP
                                    FETCH call_material03 INTO l_temp_trsn_cm;

                                    EXIT WHEN call_material03%NOTFOUND;
                                    l_temp_trsn_cm_all :=
                                           l_temp_trsn_cm_all
                                        || l_temp_trsn_cm
                                        || ',';
                                END LOOP;

                                CLOSE call_material03;

                                SELECT   LENGTH (l_temp_trsn_cm_all)
                                       - LENGTH (
                                             REPLACE (l_temp_trsn_cm_all,
                                                      ',',
                                                      ''))
                                  INTO tmp_tmp
                                  FROM DUAL;

                                -- IF l_temp_trsn_cm <> '' OR l_temp_trsn_cm IS NOT NULL
                                IF tmp_tmp >= '2'
                                THEN
                                    res :=
                                        l_temp_trsn_cm_all || ' NOT ONLINE';
                                    RAISE l_exit;
                                END IF;

                                /* --------------------------------如果某機台線邊只要有一盤物料未掃上線﹐則此機台不允許再叫料(不包括泛用機)。---------------------*/

                                /* -------------------------------------------------------檢查是否是工單連打。----------------------------------------------------*/
                                l_vwo_count := 0;

                                SELECT COUNT (*)
                                  INTO l_vwo_count
                                  FROM mes4.r_v_wo m, mes4.r_station_wip n
                                 WHERE m.t_wo = n.wo AND n.tr_sn = mydata;

                                /* -------------------------------------------------------檢查是否是工單連打。----------------------------------------------------*/

                                /* -----------------------------------------------------叫料卡有無超過工單量------------------------------------------------------*/
                                l_temp_trsn_cm := '';

                                IF l_vwo_count > 0
                                THEN
                                    OPEN call_material06;

                                    LOOP
                                        FETCH call_material06
                                            INTO l_temp_trsn_cm;

                                        EXIT WHEN call_material06%NOTFOUND;
                                        l_temp_trsn_cm :=
                                            l_temp_trsn_cm || ',';
                                    END LOOP;

                                    CLOSE call_material06;

                                    IF    l_temp_trsn_cm <> ''
                                       OR l_temp_trsn_cm IS NOT NULL
                                    THEN
                                        res := 'SCM-T03386';
                                        RAISE l_exit;
                                    END IF;
                                ELSE
                                    OPEN call_material05;

                                    LOOP
                                        FETCH call_material05
                                            INTO l_temp_trsn_cm;

                                        EXIT WHEN call_material05%NOTFOUND;
                                        l_temp_trsn_cm :=
                                            l_temp_trsn_cm || ',';
                                    END LOOP;

                                    CLOSE call_material05;

                                    IF    l_temp_trsn_cm <> ''
                                       OR l_temp_trsn_cm IS NOT NULL
                                    THEN
                                        res := 'SCM-T03386';
                                        RAISE l_exit;
                                    END IF;
                                END IF;
                            /* -----------------------------------------------------叫料卡有無超過工單量------------------------------------------------------*/
                            END IF;

                            UPDATE mes4.r_station_wip
                               SET emp_no = SUBSTR ('+' || emp_no, 1, 10)
                             WHERE station = l_ap_station AND tr_sn = mydata;

                            COMMIT;

                            INSERT INTO mes4.r_job_record
                                 VALUES ('WIP_CONTROL',
                                         l_ap_station,
                                         '',
                                         '',
                                         '',
                                         mydata,
                                         '',
                                         'NORMAL',
                                         SYSDATE);

                            COMMIT;
                        ELSE
                            res := 'RESCAN,HAVE PROMPT OK';
                            RAISE l_exit;
                        END IF;

                        DELETE mes4.r_ap_temp
                         WHERE data1 = 'SCADA-GW28' AND data2 = g_stationno;
                    --AND TO_NUMBER (data3) > 1;
                    END IF;

                    COMMIT;
                END IF;
            END IF;
        -------------------------------------------------------------'
        ELSIF l_action_code = 'ACTION-M-AB'
        THEN
            IF l_this_input = 'MACHINE'
            THEN
                IF l_ap_station <> mydata
                THEN
                    res := 'SCM-T03387:' || mydata || ',' || l_ap_station;
                    RAISE l_exit;
                END IF;

                mes1.z_station_shortage_sp ('BACKUP_SHORTAGE_TO_TEMP',
                                            '',
                                            l_ap_station,
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            l_emp,
                                            res);

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    RAISE l_exit;
                ELSE
                    DELETE mes4.r_ap_temp
                     WHERE data1 = 'SCADA-GW28' AND data2 = g_stationno;
                END IF;
            END IF;
        ELSIF l_action_code = 'ACTION-M-AR'
        THEN
            IF l_this_input = 'MACHINE'
            THEN
                IF l_ap_station <> mydata
                THEN
                    res := 'SCM-T03387:' || mydata || ',' || l_ap_station;
                    RAISE l_exit;
                END IF;

                mes1.z_station_shortage_sp ('RECOVER_SHORTAGE_FROM_TEMP',
                                            '',
                                            l_ap_station,
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            l_emp,
                                            res);

                IF SUBSTR (res, 1, 2) <> 'OK'
                THEN
                    RAISE l_exit;
                ELSE
                    DELETE mes4.r_ap_temp
                     WHERE data1 = 'SCADA-GW28' AND data2 = g_stationno;
                END IF;
            END IF;
        -------------------------------------------------------------'

        ------SMT物料預警 IPQC CHECK  Ryan ----------
        ELSIF l_action_code = 'ACTION-M-AC'
        THEN
            IF l_this_input = 'MACHINE'
            THEN
                IF l_ap_station <> mydata
                THEN
                    res := 'SCM-T03387:' || mydata || ',' || l_ap_station;
                    RAISE l_exit;
                END IF;

                ------CHECK 掃入的機台是否是在線存在------
                SELECT COUNT (*)
                  INTO l_count
                  FROM mes4.r_station_wip
                 WHERE station = mydata AND ROWNUM = 1;

                IF l_count = 0
                THEN
                    res := 'SCM-T03397';
                    RAISE l_exit;
                ELSE
                    ------CHECK 物料是否上滿------
                    SELECT COUNT (*)
                      INTO tmp_tmp
                      FROM mes4.r_station_wip
                     WHERE     station = mydata
                           AND tr_sn IS NULL
                           AND standard_qty <> 0;

                    IF tmp_tmp > 0
                    THEN
                        ------沒有上滿提示上料--------
                        SELECT slot_no
                          INTO l_slot
                          FROM mes4.r_station_wip
                         WHERE     station = mydata
                               AND tr_sn IS NULL
                               AND standard_qty <> 0
                               AND ROWNUM < 2;

                        res := 'SCM-T03387:' || mydata || ',' || l_slot;
                    --RAISE l_exit;
                    END IF;

                    -----UPDATE 下一掃描 類型--------
                    l_next_input := 'SLOT NO';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'MACHINE',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK MACHINE';
                END IF;
            ELSIF l_this_input = 'SLOT NO'
            THEN
                SELECT data5
                  INTO l_machine
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'MACHINE'
                       AND ROWNUM = 1;

                --IF END IS WANNA...
                IF mydata = 'END'
                THEN
                    res := 'CHECK OK';

                    INSERT INTO mes4.r_job_record
                         VALUES ('IPQC_CHECK_KP',
                                 l_machine,
                                 '',
                                 '',
                                 '',
                                 '',
                                 '',
                                 '',
                                 SYSDATE);

                    COMMIT;

                    DELETE mes4.r_ap_temp
                     WHERE data1 = 'SCADA-GW28' AND data2 = g_stationno;

                    COMMIT;
                    res := 'OK SLOT NO';
                    RAISE l_exit;
                END IF;

                ----------CHECK SLOT_NO------------'
                SELECT COUNT (*)
                  INTO tmp_tmp
                  FROM mes4.r_station_wip
                 WHERE     station = l_machine
                       AND slot_no = mydata
                       AND ROWNUM = 1;

                IF tmp_tmp = 0
                THEN
                    res := 'SCM-T03388:' || l_machine || ',' || mydata;
                    RAISE l_exit;
                ELSE
                    l_next_input := 'TR SN';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'SLOT NO',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK SLOT NO';
                END IF;
            ELSIF l_this_input = 'TR SN'
            THEN
                --res := 'OK';
                res := 'SCM-T03379:' || mydata;

                SELECT mes1.get_scan_sn (mydata) INTO g_tr_sn FROM DUAL;

                IF    INSTR (g_tr_sn, 'INVALID') > 0
                   OR INSTR (g_tr_sn, 'ERROR') > 0
                THEN
                    --res := '料盘序号不存在 11,仓库未发料' || mydata;
                    res := 'SCM-T03368:' || mydata;
                    RAISE l_exit;
                END IF;

                SELECT data5
                  INTO l_machine
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'MACHINE'
                       AND ROWNUM = 1;

                SELECT data5
                  INTO l_slot
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'SLOT NO'
                       AND ROWNUM = 1;

                -------機台中掃描的軌道,在系統中正在使用的TR_SN與實際掃描的TR_SN進行對比------
                SELECT tr_sn
                  INTO l_temp_trsn
                  FROM mes4.r_station_wip
                 WHERE station = l_machine AND slot_no = l_slot;

                IF l_temp_trsn <> g_tr_sn
                THEN
                    UPDATE mes4.r_kp_list
                       SET ipqc_check_emp = l_emp,
                           ipqc_check_time = SYSDATE,
                           ipqc_check_result = 'FAIL'
                     WHERE     tr_sn = g_tr_sn
                           AND station = l_machine
                           AND end_time IS NULL
                           AND start_time IN
                                   (SELECT MAX (start_time)
                                      FROM mes4.r_kp_list
                                     WHERE     tr_sn = g_tr_sn
                                           AND station = l_machine
                                           AND end_time IS NULL);

                    res := 'SCM-T03389:' || g_tr_sn || ',' || l_temp_trsn;
                    RAISE l_exit;
                ELSE
                    UPDATE mes4.r_kp_list
                       SET ipqc_check_emp = l_emp,
                           ipqc_check_time = SYSDATE,
                           ipqc_check_result = 'PASS',
                           data1 = l_slot
                     WHERE     tr_sn = g_tr_sn
                           AND station = l_machine
                           AND end_time IS NULL
                           AND start_time IN
                                   (SELECT MAX (start_time)
                                      FROM mes4.r_kp_list
                                     WHERE     tr_sn = g_tr_sn
                                           AND station = l_machine
                                           AND end_time IS NULL);
                END IF;

                DELETE mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND TO_NUMBER (data3) > 3;

                COMMIT;
                res := 'OK TR SN';
            END IF;
        ----SMT FEEDER 在線鎖定------
        ELSIF SUBSTR (l_action_code, 1, 11) = 'ACTION-M-FL'
        THEN
            IF l_this_input = 'SLOT NO'
            THEN
                --IF END IS WANNA...
                IF mydata = 'END'
                THEN
                    DELETE mes4.r_ap_temp
                     WHERE data1 = 'SCADA-GW28' AND data2 = g_stationno;

                    COMMIT;
                    res := 'OK SLOT NO';
                    RAISE l_exit;
                END IF;

                ----------CHECK SLOT_NO------------'
                SELECT COUNT (*)
                  INTO tmp_tmp
                  FROM mes4.r_station_wip
                 WHERE     station = l_ap_station
                       AND slot_no = mydata
                       AND feeder_no IS NOT NULL
                       AND ROWNUM = 1;

                IF tmp_tmp = 0
                THEN
                    res := 'SCM-T03388:' || l_ap_station || ',' || mydata;
                    RAISE l_exit;
                ELSE
                    l_next_input := 'FEEDER NO';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'SLOT NO',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK SLOT NO';
                END IF;
            ELSIF l_this_input = 'FEEDER NO'
            THEN
                SELECT data5
                  INTO l_slot
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'SLOT NO'
                       AND ROWNUM = 1;

                SELECT feeder_no, wo, p_no
                  INTO l_feeder, l_wo, l_p_no
                  FROM mes4.r_station_wip
                 WHERE station = l_ap_station AND slot_no = l_slot;

                IF l_feeder <> mydata
                THEN
                    res := 'SCM-T03390:' || mydata;
                    RAISE l_exit;
                ELSE
                    res := 'OK,FEEDER IS LOCK';

                    UPDATE mes1.c_feeder_config
                       SET use_flag = 4
                     WHERE feeder_no = mydata;

                    IF l_action_code = 'ACTION-M-FLJ'
                    THEN
                        ERROR_CODE := 'SCM-T03398';
                    ELSIF l_action_code = 'ACTION-M-FLP'
                    THEN
                        ERROR_CODE := 'SCM-T03399';
                    ELSIF l_action_code = 'ACTION-M-FLL'
                    THEN
                        ERROR_CODE := 'SCM-T03400';
                    ELSIF l_action_code = 'ACTION-M-FLC'
                    THEN
                        ERROR_CODE := 'SCM-T03401';
                    ELSIF l_action_code = 'ACTION-M-FLG'
                    THEN
                        ERROR_CODE := 'SCM-T03402';
                    ELSIF l_action_code = 'ACTION-M-FLO'
                    THEN
                        ERROR_CODE := 'SCM-T03403';
                    END IF;

                    INSERT INTO mes4.r_feeder_change_detail_t (station,
                                                               solt,
                                                               wo,
                                                               p_no,
                                                               feeder_no,
                                                               request_time,
                                                               online_flag,
                                                               data1)
                         VALUES (l_ap_station,
                                 l_slot,
                                 l_wo,
                                 l_p_no,
                                 mydata,
                                 SYSDATE,
                                 '0',
                                 ERROR_CODE);

                    DELETE mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data3 NOT IN ('0',
                                             '1',
                                             '2',
                                             '3');

                    COMMIT;
                END IF;
            END IF;
        ---SMT FEDEDER 解鎖-----
        ELSIF l_action_code = 'ACTION-M-FU'                   ----WANGYAN-----
        THEN
            IF l_this_input = 'FEEDER NO'
            THEN
                ---在R_STATION_WIP表中找到在線生產的工單機種----2013/11/9
                SELECT COUNT (*)
                  INTO l_count
                  FROM mes4.r_station_wip
                 WHERE station = l_ap_station;

                IF l_count = 0
                THEN
                    res := 'SCM-T03419:' || l_ap_station;
                    RAISE l_exit;
                ELSE
                    SELECT wo, p_no
                      INTO l_wo, l_p_no
                      FROM mes4.r_station_wip
                     WHERE station = l_ap_station AND ROWNUM = 1;
                ---AND slot_no = l_slot;
                END IF;

                SELECT COUNT (*)
                  INTO l_count
                  FROM mes4.r_feeder_change_detail_t
                 WHERE     station = l_ap_station
                       AND wo = l_wo
                       AND online_flag = '0'
                       AND new_feederno = mydata;

                IF l_count > 0
                THEN
                    res := 'SCM-T03428';
                    RAISE l_exit;
                ELSE
                    SELECT solt
                      INTO l_slot
                      FROM mes4.r_feeder_change_detail_t
                     WHERE     station = l_ap_station
                           AND wo = l_wo
                           AND online_flag = '1'
                           AND new_feederno = mydata
                           AND ROWNUM = 1;

                    SELECT feeder_no
                      INTO l_feeder
                      FROM mes4.r_station_wip
                     WHERE     station = l_ap_station
                           AND wo = l_wo
                           AND slot_no = l_slot;
                END IF;

                IF l_feeder <> mydata
                THEN
                    res := 'SCM-T03423:' || mydata || ',' || l_feeder;
                    RAISE l_exit;
                ELSE
                    res := 'OK,FEEDER  UNLOCK';

                    UPDATE mes4.r_feeder_change_detail_t
                       SET online_flag = '2'
                     WHERE     station = l_ap_station
                           AND solt = l_slot
                           AND wo = l_wo
                           AND new_feederno = mydata;

                    DELETE mes4.r_ap_temp
                     WHERE     data1 = 'SCADA-GW28'
                           AND data2 = g_stationno
                           AND data3 NOT IN ('0',
                                             '1',
                                             '2',
                                             '3');

                    COMMIT;
                END IF;
            END IF;
        ELSIF l_action_code = 'ACTION-M-FK'
        THEN
            IF l_this_input = 'ERROR CODE'
            THEN
                SELECT COUNT (*)
                  INTO l_count
                  FROM mes1.c_feeder_error_config
                 WHERE ERROR_CODE = mydata;

                IF l_count < 1
                THEN
                    res := 'THIS ERROR CODE IS NOT EXISTS';
                    RAISE l_exit;
                END IF;

                SELECT error_desc
                  INTO l_error_desc
                  FROM mes1.c_feeder_error_config
                 WHERE ERROR_CODE = mydata;

                l_next_input := 'FEEDER NO';

                INSERT INTO mes4.r_ap_temp (data1,
                                            data2,
                                            data3,
                                            data4,
                                            data5,
                                            data6,
                                            data7,
                                            work_time)
                     VALUES ('SCADA-GW28',
                             g_stationno,
                             TO_CHAR (TO_NUMBER (l_sequence) + 1),
                             'ERROR CODE',
                             l_error_desc,
                             l_next_input,
                             '0',
                             SYSDATE);

                COMMIT;
                res := 'OK ERROR CODE';
            ELSIF l_this_input = 'FEEDER NO'
            THEN
                SELECT data5
                  INTO l_error_desc
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'ERROR CODE'
                       AND ROWNUM = 1;

                SELECT COUNT (*)
                  INTO l_count
                  FROM mes1.c_feeder_config
                 WHERE feeder_no = mydata;

                IF l_count < 1
                THEN
                    res := 'THE FEEDER IS NOT EXISTS';
                    RAISE l_exit;
                END IF;

                SELECT use_flag
                  INTO l_use_flag
                  FROM mes1.c_feeder_config
                 WHERE feeder_no = mydata;

                IF (l_use_flag = '0' OR l_use_flag = '7')
                THEN
                    SELECT COUNT (*)
                      INTO l_count
                      FROM mes4.r_feeder_repair_lock
                     WHERE feeder_no = mydata AND confirm_time IS NULL;

                    IF l_count > 0
                    THEN
                        res := 'SCM-T03425:' || mydata;
                        RAISE l_exit;
                    ELSE
                        INSERT INTO mes4.r_feeder_repair_lock (
                                        feeder_no,
                                        line_emp,
                                        me_emp,
                                        err_desc,
                                        last_station,
                                        priority_level,
                                        lock_time,
                                        action_mode,
                                        status)
                             VALUES (mydata,
                                     l_emp,
                                     l_emp,
                                     l_error_desc,
                                     l_ap_station,
                                     'NORMAL',
                                     SYSDATE,
                                     'Lock',
                                     'ME-Lock');

                        UPDATE mes1.c_feeder_config
                           SET use_flag = 4
                         WHERE feeder_no = mydata;

                        res := 'OK,FEEDER  LOCK';

                        DELETE mes4.r_ap_temp
                         WHERE     data1 = 'SCADA-GW28'
                               AND data2 = g_stationno
                               AND data3 NOT IN ('0',
                                                 '1',
                                                 '2',
                                                 '3');

                        COMMIT;
                    END IF;
                ELSE
                    res := 'THE FEEDER STATUS CAN NOT BEEN LOCKED!';
                    RAISE l_exit;
                END IF;
            END IF;
        --SMT 物料超領申請
        ELSIF l_action_code = 'ACTION-M-MO'
        THEN
            IF l_this_input = 'TRAVEL SN WO'
            THEN
                mes1.excess_material_apply ('TC0010',
                                            mydata,
                                            g_stationno,
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    l_next_input := 'TR SN';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'TRAVEL SN WO',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK TRAVEL_SN';
                END IF;
            ELSIF l_this_input = 'TR SN'
            THEN
                mes1.excess_material_apply ('TC0020',
                                            mydata,
                                            g_stationno,
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    l_next_input := 'TR SN/MATERIAL_QTY/END';

                    INSERT INTO mes4.r_ap_temp (data1,
                                                data2,
                                                data3,
                                                data4,
                                                data5,
                                                data6,
                                                data7,
                                                work_time)
                         VALUES ('SCADA-GW28',
                                 g_stationno,
                                 TO_CHAR (TO_NUMBER (l_sequence) + 1),
                                 'TR SN',
                                 mydata,
                                 l_next_input,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK TR_SN';
                END IF;
            ELSIF l_this_input = 'TR SN/MATERIAL_QTY/END'
            THEN
                --CHECK掃描的數量是否是個合法的數字
                IF mes1.is_number (mydata) = 'TRUE'
                THEN
                    mes1.excess_material_apply ('TC0040',
                                                mydata,
                                                g_stationno,
                                                l_emp,
                                                '',
                                                '',
                                                '',
                                                '',
                                                '',
                                                res);

                    IF SUBSTR (res, 1, 2) <> 'OK'
                    THEN
                        res := res;
                        RAISE l_exit;
                    END IF;

                    res := 'OK QTY';
                ELSE
                    IF UPPER (mydata) = 'END'
                    THEN
                        mes1.excess_material_apply ('TC0050',
                                                    mydata,
                                                    g_stationno,
                                                    l_emp,
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    res);

                        IF SUBSTR (res, 1, 2) = 'OK'
                        THEN
                            DELETE FROM
                                mes4.r_ap_temp
                                  WHERE     data1 = 'SCADA-GW28'
                                        AND data2 = g_stationno;

                            COMMIT;
                            res := 'OK';
                        END IF;
                    ELSIF REGEXP_LIKE (mydata, '^[H,R,C]\d{11}$') = TRUE
                    THEN
                        --l_next_input := 'TR SN/MATERIAL_QTY/END';
                        DELETE mes4.r_ap_temp
                         WHERE     data2 = g_stationno
                               AND data3 >= TO_NUMBER (l_sequence);

                        COMMIT;
                        mes1.g_machine_sp_worktype (mydata, g_stationno, res);

                        IF SUBSTR (res, 0, 2) <> 'OK'
                        THEN
                            res := res;
                            RAISE l_exit;
                        ELSE
                            res := 'OK';
                        END IF;
                    END IF;
                END IF;
            ELSIF l_this_input = 'END'
            THEN
                mes1.excess_material_apply ('TC0050',
                                            mydata,
                                            g_stationno,
                                            l_emp,
                                            '',
                                            '',
                                            '',
                                            '',
                                            '',
                                            res);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    DELETE FROM mes4.r_ap_temp
                          WHERE data1 = 'SCADA-GW28' AND data2 = g_stationno;

                    COMMIT;
                    res := 'OK';
                END IF;
            END IF;
        ELSIF l_action_code = 'ACTION-M-M'
        THEN
            IF l_this_input = 'MACHINE'
            THEN
                l_next_input := 'TRAVEL SN WO';

                INSERT INTO mes4.r_ap_temp (data1,
                                            data2,
                                            data3,
                                            data4,
                                            data5,
                                            data6,
                                            data7,
                                            work_time)
                     VALUES ('SCADA-GW28',
                             g_stationno,
                             TO_CHAR (TO_NUMBER (l_sequence) + 1),
                             'MACHINE',
                             mydata,
                             l_next_input,
                             '0',
                             SYSDATE);

                COMMIT;
                res := 'OK MACHINE';
            ELSIF l_this_input = 'TRAVEL SN WO'
            THEN
                --找到工站
                SELECT data5
                  INTO l_machine
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND DATA4 = 'MACHINE'
                       AND ROWNUM = 1;

                --找到面别
                SELECT DISTINCT PROCESS_FLAG
                  INTO l_process
                  FROM mes4.r_station_wip
                 WHERE station = l_machine AND wo = mydata AND ROWNUM = 1;

                MES1.Z_MODIFY_ONLINEDATA_SHORTAGE (mydata,
                                                   l_process,
                                                   l_machine,
                                                   RES);

                IF SUBSTR (res, 1, 2) = 'OK'
                THEN
                    l_next_input := 'END';
                    res := 'OK TRAVEL_SN WO';
                END IF;
            END IF;
        ELSIF l_action_code = 'ACTION-M-J'
        THEN
            --ADD BY CMS FOR CALL_MATERIAL--
            --ACTUALLY AFFECT MES4.R_STATION_WIP --
            res := 'KITTING PREPARE';
            l_newdata := l_trans_data;

            IF l_this_input = 'TR SN/END'
            THEN
                res := 'KITTING PROMPT';
                res := 'OK';

                ------CHECK SETUP SHEET-------
                SELECT station
                  INTO l_temp_machine
                  FROM mes4.r_station_wip
                 WHERE station = l_ap_station AND ROWNUM = 1;

                IF l_temp_machine = ''
                THEN
                    res := 'NOT SETUP SHEET';
                    RAISE l_exit;
                ELSE
                    SELECT COUNT (*)
                      INTO tmp_tmp
                      FROM mes4.r_station_wip
                     WHERE station = l_ap_station AND tr_sn = l_newdata;

                    IF tmp_tmp <> 1
                    THEN
                        IF UPPER (l_newdata) = 'END'
                        THEN
                            res := 'OK END';

                            DELETE mes4.r_ap_temp
                             WHERE     data1 = 'SCADA-GW28'
                                   AND data2 = g_stationno;

                            COMMIT;
                            RAISE l_exit;
                        ELSE                           ---- ALLOW SCAN SLOT_NO
                            SELECT COUNT (*)
                              INTO l_count
                              FROM mes4.r_station_wip
                             WHERE     station = l_ap_station
                                   AND slot_no = l_newdata;

                            IF l_count = 0
                            THEN
                                res :=
                                       'THIS TR_SN/SLOT_NO:'
                                    || l_newdata
                                    || ' IS NOT ONLINE';
                                RAISE l_exit;
                            ELSE
                                SELECT tr_sn
                                  INTO l_trsn_wip
                                  FROM mes4.r_station_wip
                                 WHERE     station = l_ap_station
                                       AND slot_no = l_newdata
                                       AND ROWNUM = 1;

                                l_newdata := l_trsn_wip;
                            END IF;
                        END IF;
                    END IF;

                    /*ELSE*/
                    SELECT COUNT (*)
                      INTO tmp_tmp
                      FROM mes4.r_smt_prepare
                     WHERE     station = l_ap_station
                           AND wo IN (SELECT wo
                                        FROM mes4.r_station_wip
                                       WHERE station = l_ap_station)
                           AND kp_no =
                               (SELECT cust_kp_no
                                  FROM mes4.r_tr_sn
                                 WHERE tr_sn = l_newdata AND ROWNUM = 1)
                           AND prepare_flag IN ('1', '2')
                           AND work_time > SYSDATE - 0.5;

                    IF tmp_tmp = 0
                    THEN
                        tmp_tmp := 1;

                        IF tmp_tmp > 0
                        THEN
                            OPEN call_material03;

                            LOOP
                                FETCH call_material03 INTO l_temp_trsn_cm;

                                EXIT WHEN call_material03%NOTFOUND;
                                l_temp_trsn_cm := l_temp_trsn_cm || ',';
                            END LOOP;

                            CLOSE call_material03;

                            IF    l_temp_trsn_cm <> ''
                               OR l_temp_trsn_cm IS NOT NULL
                            THEN
                                res := 'SCM-T03422:' || l_temp_trsn_cm;
                                RAISE l_exit;
                            END IF;

                            l_vwo_count := 0;

                            SELECT COUNT (*)
                              INTO l_vwo_count
                              FROM mes4.r_v_wo m, mes4.r_station_wip n
                             WHERE m.t_wo = n.wo AND n.tr_sn = l_newdata;

                            l_temp_trsn_cm := '';

                            IF l_vwo_count > 0
                            THEN
                                OPEN call_material06;

                                LOOP
                                    FETCH call_material06 INTO l_temp_trsn_cm;

                                    EXIT WHEN call_material06%NOTFOUND;
                                    l_temp_trsn_cm := l_temp_trsn_cm || ',';
                                END LOOP;

                                CLOSE call_material06;

                                IF    l_temp_trsn_cm <> ''
                                   OR l_temp_trsn_cm IS NOT NULL
                                THEN
                                    res := 'SCM-T03386';
                                    RAISE l_exit;
                                END IF;
                            ELSE
                                OPEN call_material05;

                                LOOP
                                    FETCH call_material05 INTO l_temp_trsn_cm;

                                    EXIT WHEN call_material05%NOTFOUND;
                                    l_temp_trsn_cm := l_temp_trsn_cm || ',';
                                END LOOP;

                                CLOSE call_material05;

                                IF    l_temp_trsn_cm <> ''
                                   OR l_temp_trsn_cm IS NOT NULL
                                THEN
                                    res := 'SCM-T03386';
                                    RAISE l_exit;
                                END IF;
                            END IF;
                        END IF;

                        /*UPDATE MES4.R_STATION_WIP
                           SET EMP_NO = SUBSTR ('+' || EMP_NO, 1, 10)
                         WHERE STATION = L_AP_STATION AND TR_SN = L_TRANS_DATA;*/
                        SELECT wo,
                               kp_no,
                               slot_no,
                               p_no
                          INTO l_wo,
                               l_kpno,
                               l_slot_no,
                               l_pno
                          FROM mes4.r_station_wip
                         WHERE station = l_ap_station AND tr_sn = l_newdata;

                        IF l_wo = '' OR l_kpno = ''
                        THEN
                            res := 'TR SN ' || l_newdata || ' IS NOT ON LINE';
                            RAISE l_exit;
                        ELSE
                            INSERT INTO mes4.r_smt_prepare (station,
                                                            wo,
                                                            kp_no,
                                                            slot_no,
                                                            work_time,
                                                            line_emp,
                                                            prepare_flag,
                                                            tr_sn,
                                                            p_no)
                                 VALUES (l_ap_station,
                                         l_wo,
                                         l_kpno,
                                         NVL (l_slot_no, ''),
                                         SYSDATE,
                                         l_emp,
                                         '1',
                                         l_newdata,
                                         l_pno);

                            COMMIT;
                        END IF;
                    ELSE
                        res := 'RESCAN,HAVE PROMPT OK';
                        RAISE l_exit;
                    END IF;
                /*END IF;*/
                END IF;

                l_next_input := 'TR SN/END';
            END IF;
        ELSIF l_action_code = 'ACTION-M-USC'
        THEN
            --UPDATE SPECIAL MATERIAL CONTROL DATA
            --l_ap_station  GET STATION
            --   l_process   GET PROCESS FLAG
            --l_emp    GET EMPNO
            IF l_this_input = 'TRAVEL SN WO'
            THEN
                l_next_input := 'CHECK_PROGRAM_EMP';

                --if the special control of the wo product number is configed
                SELECT COUNT (1)
                  INTO L_COUNT
                  FROM MES1.C_SKU_KP_LOC_CONTROL CSKLC, MES4.R_WO_BASE RWB
                 WHERE INSTR (CSKLC.SKU_NO, RWB.P_NO) > 0 AND RWB.WO = MYDATA;

                IF L_COUNT < 1
                THEN
                    res := 'SCM-T03687:' || mydata;
                    RAISE l_exit;
                END IF;

                --check if the wo is on line
                SELECT COUNT (1)
                  INTO L_COUNT
                  FROM MES4.R_STATION_WIP
                 WHERE     WO = MYDATA
                       AND STATION = l_ap_station
                       AND PROCESS_FLAG = l_process;

                IF L_COUNT > 0
                THEN
                    INSERT INTO MES4.R_AP_TEMP (DATA1,
                                                DATA2,
                                                DATA3,
                                                DATA4,
                                                DATA5,
                                                DATA6,
                                                DATA7,
                                                WORK_TIME)
                         VALUES ('SCADA-GW28',
                                 G_STATIONNO,
                                 TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                                 l_this_input,
                                 MYDATA,
                                 L_NEXT_INPUT,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    res := 'OK TRAVEL SN WO';
                ELSE
                    res :=
                           'SCM-T03688:'
                        || mydata
                        || ','
                        || l_ap_station
                        || ','
                        || l_process;
                    RAISE l_exit;
                END IF;

                COMMIT;
            ELSIF l_this_input = 'CHECK_PROGRAM_EMP'
            THEN
                l_next_input := 'CONFIRM_PROGRAM_PASSWORD';

                SELECT COUNT (emp_no)
                  INTO i_temp_emp_privilage
                  FROM mes1.c_ap_config
                 WHERE emp_no = mydata AND function_name = 'CHECKEMP_PROGRAM';

                IF i_temp_emp_privilage > 0
                THEN
                    INSERT INTO MES4.R_AP_TEMP (DATA1,
                                                DATA2,
                                                DATA3,
                                                DATA4,
                                                DATA5,
                                                DATA6,
                                                DATA7,
                                                WORK_TIME)
                         VALUES ('SCADA-GW28',
                                 G_STATIONNO,
                                 TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                                 l_this_input,
                                 MYDATA,
                                 L_NEXT_INPUT,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                    RES := 'OK EMP';
                ELSE
                    res := 'SCM-T03198';
                END IF;
            ELSIF l_this_input = 'CONFIRM_PROGRAM_PASSWORD'
            THEN
                l_next_input := 'TR SN';

                SELECT data5
                  INTO l_ap_emp
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'CHECK_PROGRAM_EMP'
                       AND ROWNUM = 1;

                SELECT COUNT (1)
                  INTO l_count
                  FROM mes1.c_emp
                 WHERE emp_no = l_ap_emp AND EMP_PASSWORD = MYDATA;

                IF l_count > 0
                THEN
                    res := 'OK PASSWORD';

                    INSERT INTO MES4.R_AP_TEMP (DATA1,
                                                DATA2,
                                                DATA3,
                                                DATA4,
                                                DATA5,
                                                DATA6,
                                                DATA7,
                                                WORK_TIME)
                         VALUES ('SCADA-GW28',
                                 G_STATIONNO,
                                 TO_CHAR (TO_NUMBER (L_SEQUENCE) + 1),
                                 l_this_input,
                                 MYDATA,
                                 L_NEXT_INPUT,
                                 '0',
                                 SYSDATE);

                    COMMIT;
                ELSE
                    res := 'SCM-T03085';
                END IF;
            ELSIF l_this_input = 'TR SN'
            THEN
                g_tr_sn := mes1.GET_SCAN_SN_ALLPART (mydata);

                SELECT COUNT (1)
                  INTO L_COUNT
                  FROM MES4.R_TR_SN
                 WHERE TR_SN = g_tr_sn;

                IF L_COUNT > 0
                THEN
                    SELECT CUST_KP_NO
                      INTO l_kpno
                      FROM MES4.R_TR_SN
                     WHERE TR_SN = g_tr_sn;
                ELSE
                    res := 'SCM-T03404';
                    RAISE l_exit;
                END IF;

                SELECT data5
                  INTO l_ap_emp
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'CHECK_PROGRAM_EMP'
                       AND ROWNUM = 1;


                SELECT data5
                  INTO l_WO
                  FROM mes4.r_ap_temp
                 WHERE     data1 = 'SCADA-GW28'
                       AND data2 = g_stationno
                       AND data4 = 'TRAVEL SN WO'
                       AND ROWNUM = 1;

                SELECT COUNT (1)
                  INTO L_COUNT
                  FROM MES4.R_MATERIAL_CONTROL_DETAIL
                 WHERE     WO = l_WO
                       AND STATION_NAME = l_ap_station
                       AND PROCESS_FLAG = l_process
                       AND CUST_KP_NO = l_kpno
                       AND kp_flag = '0';

                IF L_COUNT > 0
                THEN
                    res :=
                           'SCM-T03689:'
                        || mydata
                        || ','
                        || l_ap_station
                        || ','
                        || l_process;
                    RAISE l_exit;
                END IF;


                SELECT COUNT (1)
                  INTO L_COUNT
                  FROM MES4.R_MATERIAL_CONTROL_DETAIL
                 WHERE     WO = l_WO
                       AND STATION_NAME = l_ap_station
                       AND PROCESS_FLAG = l_process
                       AND kp_flag = '0';

                IF L_COUNT > 0
                THEN
                    INSERT INTO MES4.R_MATERIAL_CONTROL_DETAIL (WO,
                                                                STATION_NAME,
                                                                WORK_FLAG,
                                                                ME_EMPNO,
                                                                ME_TIME,
                                                                CUST_KP_NO,
                                                                EDIT_EMP,
                                                                EDIT_TIME,
                                                                SMT_CODE,
                                                                SLOT_NO,
                                                                PROCESS_FLAG)
                        SELECT WO,
                               STATION_NAME,
                               '1',
                               l_ap_emp,
                               SYSDATE,
                               l_kpno,
                               l_emp,
                               SYSDATE,
                               SMT_CODE,
                               SLOT_NO,
                               PROCESS_FLAG
                          FROM MES4.R_MATERIAL_CONTROL_DETAIL
                         WHERE     WO = l_WO
                               AND STATION_NAME = l_ap_station
                               AND PROCESS_FLAG = l_process
                               AND kp_flag = '0';

                    UPDATE MES4.R_MATERIAL_CONTROL_DETAIL
                       SET KP_FLAG = '1',
                           LAST_EMP = l_emp,
                           LAST_TIME = SYSDATE
                     WHERE     WO = l_WO
                           AND STATION_NAME = l_ap_station
                           AND PROCESS_FLAG = l_process
                           AND CUST_KP_NO IS NOT NULL
                           AND KP_FLAG = '0';

                    COMMIT;
                ELSE
                    res :=
                           'SCM-T03687:'
                        || mydata
                        || ','
                        || l_ap_station
                        || ','
                        || l_process;
                    RAISE l_exit;
                END IF;
            END IF;
        END IF;
    --結束作業代碼的分類
    --res := 'OK';
    END IF;                                                        --結束作業代碼的判斷
EXCEPTION
    WHEN l_exit
    THEN
        res := res || '/' || mydata;
    WHEN NO_DATA_FOUND
    THEN
        IF res = 'OLD TR SN NOT EXIST'
        THEN
            OPEN old_trsn (mydata);

            FETCH old_trsn INTO l_work_flag, l_location_flag;

            IF old_trsn%FOUND
            THEN
                IF l_work_flag = '1'
                THEN
                    res := 'TR SN HAS USED UP';
                ELSIF l_work_flag = '0'
                THEN
                    IF l_location_flag = '0'
                    THEN
                        res := 'SCM-T03129';
                    ELSIF l_location_flag = '1'
                    THEN
                        res := 'SCM-T03128';
                    ELSIF l_location_flag = '2'
                    THEN
                        res := 'SCM-T03154';
                    ELSIF l_location_flag = '3'
                    THEN
                        res := 'SCM-T03150';
                    END IF;
                ELSIF l_work_flag = '2'
                THEN
                    res := 'SCM-T03164';
                ELSIF l_work_flag = '3'
                THEN
                    res := 'SCM-T03165';
                END IF;
            END IF;
        ELSE
            res := 'SCM-T03082';
        END IF;
    WHEN exp1
    THEN
        res := 'SCM-T03144';
    WHEN exception_a
    THEN
        res := 'exception_a' || mydata;
    WHEN exp2
    THEN
        --上午 10:39 2003/11/06  修改提示信息
        IF mydata IN ('ACTION-S-A',
                      'ACTION-S-B',
                      'ACTION-S-C',
                      'ACTION-S-D',
                      'ACTION-S-E',
                      'ACTION-S-F',
                      'ACTION-S-G',
                      --WRONG... ...
                      'ACTION-S-H',
                      'ACTION-AOI',
                      'ACTION-M-K',
                      'ACTION-M-P',
                      'ACTION-M-SO',
                      'ACTION-M-SF')
        THEN
            res := 'CODE IS NOT MATCH MACHINE';
        ELSE
            res := 'NO ACTION CODE';
        END IF;
    WHEN OTHERS
    THEN
        res :=
               res
            || '/'
            || SQLERRM (SQLCODE)
            || mydata
            || DBMS_UTILITY.format_error_backtrace ();
END;
/
