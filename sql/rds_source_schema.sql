--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: grn_daily_main; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grn_daily_main (
    id bigint NOT NULL,
    grn_date timestamp without time zone,
    supplier_code character varying(255),
    supplier_name character varying(255),
    item_ctag_code character varying(255),
    item_ctag_name character varying(255),
    item_code character varying(255),
    item_name character varying(255),
    um character varying(255),
    stock_type_name character varying(255),
    grn_number character varying(255),
    purchase_order_number character varying(255),
    department character varying(255),
    department_name character varying(255),
    indent_number character varying(255),
    currency_code character varying(255),
    exchange_rate character varying(255),
    cost_project character varying(255),
    cost_project_name character varying(255),
    currency_name character varying(255),
    challan_qty character varying(255),
    rate character varying(255),
    net_amount character varying(255),
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.grn_daily_main OWNER TO postgres;

--
-- Name: pur_order_daily_main; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pur_order_daily_main (
    id bigint NOT NULL,
    order_date timestamp without time zone,
    supplier_code character varying(255),
    supplier_name character varying(255),
    item_category_code character varying(255),
    item_category_name character varying(255),
    item_code character varying(255),
    item_name character varying(255),
    um character varying(255),
    order_number character varying(255),
    entered_by_name character varying(255),
    indent_number character varying(255),
    department character varying(255),
    department_name character varying(255),
    cost_project character varying(255),
    cost_project_name character varying(255),
    currency_code character varying(255),
    currency_name character varying(255),
    exchange_rate character varying(255),
    stock_type_name character varying(255),
    order_value character varying(255),
    order_quantity character varying(255),
    bal_qty character varying(255),
    rate character varying(255),
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.pur_order_daily_main OWNER TO postgres;

--
-- Name: issue_daily_main; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.issue_daily_main (
    id bigint NOT NULL,
    issue_date timestamp without time zone,
    item_category_code character varying(255),
    item_category_name character varying(255),
    department_code character varying(255),
    department_name character varying(255),
    item_code character varying(255),
    cost_centre_code character varying(255),
    cost_name character varying(255),
    item_name character varying(255),
    um character varying(255),
    quantity character varying(255),
    rate character varying(255),
    value character varying(255),
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.issue_daily_main OWNER TO postgres;

--
-- Name: grn_daily_main_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.grn_daily_main_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grn_daily_main_id_seq OWNER TO postgres;

--
-- Name: grn_daily_main_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.grn_daily_main_id_seq OWNED BY public.grn_daily_main.id;


--
-- Name: issue_daily_main_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.issue_daily_main_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.issue_daily_main_id_seq OWNER TO postgres;

--
-- Name: issue_daily_main_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.issue_daily_main_id_seq OWNED BY public.issue_daily_main.id;


--
-- Name: pur_order_daily_main_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pur_order_daily_main_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pur_order_daily_main_id_seq OWNER TO postgres;

--
-- Name: pur_order_daily_main_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pur_order_daily_main_id_seq OWNED BY public.pur_order_daily_main.id;


--
-- Name: grn_daily_main id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grn_daily_main ALTER COLUMN id SET DEFAULT nextval('public.grn_daily_main_id_seq'::regclass);


--
-- Name: issue_daily_main id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.issue_daily_main ALTER COLUMN id SET DEFAULT nextval('public.issue_daily_main_id_seq'::regclass);


--
-- Name: pur_order_daily_main id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pur_order_daily_main ALTER COLUMN id SET DEFAULT nextval('public.pur_order_daily_main_id_seq'::regclass);


--
-- Name: grn_daily_main grn_daily_main_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grn_daily_main
    ADD CONSTRAINT grn_daily_main_pkey PRIMARY KEY (id);


--
-- Name: grn_daily_main grn_main_unique_cols; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grn_daily_main
    ADD CONSTRAINT grn_main_unique_cols UNIQUE (grn_date, item_code, grn_number, purchase_order_number, department, cost_project);


--
-- Name: issue_daily_main issue_daily_main_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.issue_daily_main
    ADD CONSTRAINT issue_daily_main_pkey PRIMARY KEY (id);


--
-- Name: issue_daily_main issue_main_unique_cols; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.issue_daily_main
    ADD CONSTRAINT issue_main_unique_cols UNIQUE (issue_date, item_code, cost_centre_code, department_code);


--
-- Name: pur_order_daily_main pur_main_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pur_order_daily_main
    ADD CONSTRAINT pur_main_unique UNIQUE (order_date, item_code, order_number, department, cost_project);


--
-- Name: pur_order_daily_main pur_order_daily_main_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pur_order_daily_main
    ADD CONSTRAINT pur_order_daily_main_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

