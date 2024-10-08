alter session set "_oracle_script" = true;

create user threego
identified by threego
default tablespace users;
grant connect, resource to threego;
alter user threego quota unlimited on users;
-- drop user threego cascade;

-- select sid, serial#, username,status from v$session where username = 'THREEGO';
-- alter system kill SESSION '754,48317';
 
---------------------------------------------------------------

-- 회원 테이블 
create table member(
    id 	varchar2(30),	
    pwd	varchar2(300) not null,
    name varchar2(20) not null,
    email varchar2(200),	
    phone char(11) not null,
    member_role char(1) default 'U',
    post char(5) not null,
    address	varchar2(400) not null,
    reg_date date default sysdate,	
    constraints pk_member_id primary key(id),
    constraints uq_member_phone unique(phone),
    constraints uq_member_email unique(email),
    constraints ck_member_role check (member_role in ('A', 'R', 'U'))
);

-- 이용권 테이블 
create table ticket(
    tic_id 	varchar2(30),      
    tic_name varchar2(30) not null,
    tic_cnt number not null,
    tic_price number not null,
    constraint  pk_ticket_tic_id primary key(tic_id)
    );        

-- 구매 테이블 
create table payment(
    p_no	number,
    p_mem_id	varchar2(30),
    p_tic_id varchar2(30),
    p_date date default sysdate,
    p_cnt number, 
    p_use_cnt number,
    constraint  pk_payment_p_no primary key(p_no),
    constraints fk_payment_mem_id foreign key(p_mem_id) references member (id) on delete set null,
    constraints fk_paymente_tic_no foreign key(p_tic_id) references ticket(tic_id) on delete set null
   );  
 create sequence seq_payment_no;  
 
 -- 구매내역 상세 테이블 
create table paymentDetail(
    pd_no   number,
    pd_mem_id varchar2(30),
    pd_tic_id   varchar2(30),
    pd_tic_price number,
    pd_date date default sysdate,
    constraint  pk_payment_pd_no primary key(pd_no),
    constraints fk_payment_pd_mem_id foreign key(pd_mem_id) references member(id) 
);
create sequence seq_pd_no;


-- 구매내역  trigger
CREATE OR REPLACE TRIGGER trg_insert_payment_detail
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
  INSERT INTO paymentDetail (pd_no, pd_mem_id, pd_tic_id, pd_tic_price, pd_date)
  VALUES (seq_pd_no.NEXTVAL, :NEW.p_mem_id, (SELECT tic_id FROM ticket WHERE tic_id = :NEW.p_tic_id), (SELECT tic_price FROM ticket WHERE tic_id = :NEW.p_tic_id), :NEW.p_date);
END;
/

-- 수거요청 테이블 
create table request(
    req_no   number,
    req_writer varchar2(30) not null,
    req_location_id   varchar2(30) not null,
    req_post char(5) not null,
    req_address   varchar2(400) not null,
    req_photo varchar2(200) not null,
    req_status   char(1) default '0',
    req_date   date default sysdate,
    req_rider varchar2(30) , 
    req_cp_date date default null,
    constraints pk_request_req_no primary key(req_no),
    constraints fk_request_id foreign key(req_writer) references member(id) on delete cascade, 
    constraints fk_request_location_id foreign key(req_location_id) references location(l_id) on delete cascade,
    constraints fk_req_rider foreign key(req_rider) references rider(r_id) on delete cascade,
    constraints ck_request_status check( req_status in ('0', '1', '2', '3'))
    -- 0 수거 대기중, 1 수거중,  2 수거완료 3 수거취소
);
 create sequence seq_req_no;

-- 게시판 테이블  
create table board(
    b_no number,
    b_type	varchar2(30) not null,
    b_tittle varchar2(500) not null,
    b_writer varchar2(30) not null,
    b_content varchar2(4000) not null,
    b_reg_date date default sysdate,
    constraints pk_board_b_no primary key(b_no),
    constraints fk_board_b_writer foreign key(b_writer) references member(id) on delete cascade,
    constraints ck_board_b_type check(b_type in ('N', 'Q'))
    -- N : 공지사항 Q : 이용문의
);
 create sequence seq_board_no;


-- 게시판 댓글 테이블 
create table board_comment(
    c_no number,
    c_level number default 1,
    c_writer varchar2(30),
    c_content varchar2(4000) not null,
    c_board_no number not null,
    c_reg_date date default sysdate,
    constraints pk_board_comment_c_no primary key(c_no),
    constraints fk_board_comment_c_writer foreign key(c_writer) references member(id) on delete cascade,
    constraints fk_board_comment_c_ref foreign key(c_board_no) references board(b_no) on delete cascade
);
 create sequence seq_c_no;


-- 지역 테이블
create table location(
    l_id varchar2(30),	
    l_name	varchar2(20) not null,
    constraints pk_location_l_no primary key(l_id)
);

-- 라이더 테이블
create table rider(
    r_id varchar2(30),
    r_location_id varchar2(30),
    r_status char(1) default '0',
    r_reg_date date default sysdate,
    up_date	date default null,
    fileName varchar2(500) not null,
    constraints pk_r_id primary key(r_id),
    constraints fk_rider_r_id  foreign key(r_id) references member(id) on delete cascade,
    constraints fk_rider_location_id foreign key(r_location_id) references location(l_id) on delete set null,
    constraints ck_rider_r_status check (r_status in ('0', '1'))
    -- 0 승인 대기중 1 승인완료
);

-- 탈퇴 회원 테이블 
create table del_member(
del_id varchar2(30),
del_pwd varchar2(300)	 not null,
del_email	varchar2(200),	
del_phone char(11)	not null,
del_role	 char(1),	
del_address 	varchar2(400)	not null,
del_reg_date date,	
del_date date
);

-- 탈퇴회원 트리거
CREATE OR REPLACE TRIGGER  trig_member_delete
before DELETE ON member
FOR EACH ROW
BEGIN
    INSERT INTO del_member (del_id, del_pwd, del_email, del_phone, del_role, del_address, del_reg_date, del_date)
    VALUES (:old.id, :old.pwd, :old.email, :old.phone, :old.member_role, :old.address, :old.reg_date, SYSDATE);
END;
/

-- 신고 테이블 
create table warning(
w_no	 number,		
w_req_no	number not null,	
w_writer  varchar2(30)	not null,	  
w_content varchar2(4000)	not null,	
w_reg_date date default sysdate,
w_confirm number default 0, 
w_caution varchar2(4000),
constraints pk_warning_w_no primary key(w_no),
constraints fk_warning_w_req_no foreign key(w_req_no) references request(req_no) on delete cascade,
constraints fk_warning_w_id foreign key(w_writer) references member(id) on delete cascade,
constraints ck_warning_w_confirm check(w_confirm in(0, 1))
-- 0 신고확인중  1 신고확인완료
);
create sequence seq_w_no;

-- 메시지 테이블
create table msgbox(
    msg_no number, 
    msg_type varchar2(50) not null, 
    msg_sender varchar2(30) not null, 
    msg_receiver varchar2(30) not null, 
    msg_content varchar2(4000), 
    msg_sending_date date default sysdate,
    msg_confirm char(1) default 'X',
    constraints pk_msgbox_msg_no primary key(msg_no),
    constraints fk_msgbox_msg_sender foreign key(msg_sender) references member(id) on delete cascade,
    constraints ck_msgbox_msg_type check(msg_type in('C', 'A', 'P')),
    constraints ck_msgbox_msg_confirm check(msg_confirm in ('O', 'X'))
    -- c 는 조치 ,  a 는 승인 알람,  p는 진행상황알람 
);
create sequence seq_msg_no;


select * from msgbox;
-- 여기까지 테이블 , 시퀀스, 트리거 생성 쿼리만! 

--------------------------------------------------------------------------------------------------------------------------------------------

-- 시연용 
-- member
 



-- ticket
 insert into ticket values (
    'tic1', '1회권',1,5000 
 );
  insert into ticket values (
    'tic3', '3회권',3,15000 
 );
  insert into ticket values (
    'tic5', '5회권',5,23900 
 );
  insert into ticket values (
    'tic10', '10회권',10,46900 
 );

-- 구매

 

-- 지역구
insert into location values(
    'S1', '강남구, 서초구'
);
insert into location values(
    'S2', '송파구, 강동구'
);
insert into location values(
    'S3', '광진구,성동구'
);



-- commit;
-------------------------------------------------------------------------------------------------------------------------------------
--전체 테이블 조회
select * from member;
select * from ticket;
select * from location;
select * from rider;
select * from request; 
select * from payment;
select * from paymentDetail;
select * from del_member;
select * from msgbox;
select * from warning;
select * from board;
select * from board_comment;
--------------------------------------------------------------------------------------------------------------------------------------------

SELECT r.*, loc.l_name AS location_name 
FROM (SELECT rr.*, ROWNUM AS rnum FROM (SELECT * FROM request WHERE req_rider = 'disney1026') rr WHERE ROWNUM <= 1) r 
JOIN location loc ON loc.l_id = r.req_location_id WHERE rnum >= 10;