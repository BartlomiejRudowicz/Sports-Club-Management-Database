create table Pracownicy(
	id_pracownika number(6) primary key check(id_pracownika>0),
	imie varchar2(30) not null,
	nazwisko varchar2(30) not null,
	data_urodzenia date not null,
	typ char(1) NOT NULL CHECK(typ IN ('Z', 'C', 'T')),
	constraint dane_pracownikow unique(imie, nazwisko, data_urodzenia));
create table Zawodnicy(
	id_zawodnika number(6) primary key,
	numer_koszulki number(2) not null unique check(numer_koszulki>0),
	pozycja varchar2(30) not null,
	funkcja_boiskowa varchar2(30),
	cena_rynkowa number(10) check(cena_rynkowa>=0),
	foreign key(id_zawodnika)
		references Pracownicy(id_pracownika) on delete cascade);
create table Czlonkowie_zarzadu(
	id_czlonka_zarzadu number(6) primary key,
	rola_zarzadcza varchar2(30) not null,
	foreign key(id_czlonka_zarzadu)
		references Pracownicy(id_pracownika) on delete cascade);
create table Trenerzy(
	id_trenera number(6) primary key,
	obszar_trenerski varchar2(30) not null,
	foreign key(id_trenera)
		references Pracownicy(id_pracownika) on delete cascade);
create table Badania_zdrowotne(
	id_badania number(6),
	id_badanego number(6) not null,
	data_badania date not null,
	stan_zdrowia varchar2(150) not null,
	poziom_zmeczenia varchar2(30) not null,
	ryzyko_kontuzji varchar2(30) not null,
	constraint dane_badania unique(id_badanego, data_badania),
	foreign key(id_badanego)
		references Zawodnicy(id_zawodnika),
	primary key(id_badania));
create table Kontrakty(
	id_zakontraktowanego number(6) not null,
	id_kontraktu number(6),
	data_rozpoczecia_kontraktu date not null,
	data_wygasniecia_kontraktu date not null,
	wynagrodzenie_miesieczne number(8) not null check(wynagrodzenie_miesieczne>=0),
	klauzula_odstepnego number(11) not null check(klauzula_odstepnego>=0),
	premie_miesieczne number(10) check(premie_miesieczne>=0),
	constraint dane_kontraktu unique(id_zakontraktowanego, data_rozpoczecia_kontraktu, data_wygasniecia_kontraktu),
	foreign key(id_zakontraktowanego)
		references Pracownicy(id_pracownika),
	primary key(id_kontraktu));
create table Obiekty_klubowe(
	id_obiektu number(6) primary key,
	nazwa_obiektu varchar2(60) not null,
	typ_obiektu varchar2(30) not null,
	pojemnosc number(6) not null check(pojemnosc>=0),
	lokalizacja varchar2(50) not null,
	constraint dane_obiektu unique(nazwa_obiektu),
	ceny_biletow number(6) check(ceny_biletow>=0));
create table Treningi(
	id_trenera_prowadzacego number(6) not null,
	id_treningu number(6) primary key check(id_treningu>0),
	data_treningu date not null,
	godzina_rozpoczecia timestamp not null,
	godzina_zakonczenia timestamp not null,
	id_obiektu_treningowego number(6) not null,
	constraint informacje_treningowe unique(data_treningu, godzina_rozpoczecia, godzina_zakonczenia),
	foreign key(id_trenera_prowadzacego) 
		references Trenerzy(id_trenera),
	foreign key(id_obiektu_treningowego)
		references Obiekty_klubowe(id_obiektu));
create table Mecze(
	id_meczu number(6) primary key,
	data_meczu date not null,
	przeciwnik varchar2(50) not null,
	typ_rozgrywek varchar2(40) not null,
	status_meczu varchar2(30) not null,
	gole_strzelone number(3) check(gole_strzelone>=0),
	gole_stracone number(3) check(gole_stracone>=0),
	constraint dane_meczu unique(data_meczu),
	typ_meczu char(1) not null check(typ_meczu in('D', 'W')));
create table Mecze_domowe(
	id_meczu_domowego number(6) primary key,
	id_obiektu_meczowego number(6) not null references
		Obiekty_klubowe(id_obiektu),
	foreign key(id_meczu_domowego) references Mecze(id_meczu) on delete cascade);
create table Mecze_wyjazdowe(
	id_meczu_wyjazdowego number(6) primary key,
	stadion_wyjazdowy varchar2(60) not null,
	foreign key(id_meczu_wyjazdowego) references Mecze(id_meczu) on delete cascade);
create table Statystyki_zawodnikow(
	id_statystyk number(6),
	liczba_bramek number(2) not null check(liczba_bramek>=0),
	liczba_asyst number(2) not null check(liczba_asyst>=0),
	minuty_na_boisku number(3) not null check(minuty_na_boisku>=0),
	procent_celnych_podan number(3) not null check(procent_celnych_podan between 0 and 100),
	podania number(4) not null check(podania>=0),
	odebrane_pilki number(3) not null check(odebrane_pilki>=0),
	liczba_strzalow number(2) not null check(liczba_strzalow>=0),
	obronione_lub_zablokowane_strzaly number(2) not null check(obronione_lub_zablokowane_strzaly>=0),
	id_meczu number(6) not null references Mecze(id_meczu),
	id_zawodnika number(6) not null references Zawodnicy(id_zawodnika),
	constraint dane_statystyk unique(id_meczu, id_zawodnika),
	primary key(id_statystyk));
create table Uczestnicy_treningow (
    id_uczestnictwa number(6),
    czy_indywidualny char(1) not null check (czy_indywidualny in ('T', 'N')),
    grupa_treningowa varchar2(30) not null,
    id_zawodnika number(6) not null references Zawodnicy(id_zawodnika),
    id_treningu number(6) not null,
    constraint dane_uczestnictwa unique (id_treningu, id_zawodnika),
    primary key (id_uczestnictwa),
    foreign key (id_treningu) references Treningi(id_treningu)
);
create table Transfery(
	id_transferowanego number(6) not null,
	id_transferu number(6),
	data_transferu date not null,
	typ_transferu varchar2(30) not null,
	oplata_transferowa number(11) not null check(oplata_transferowa>=0),
	foreign key(id_transferowanego) references Pracownicy(id_pracownika),
	constraint dane_transferu unique(id_transferowanego, data_transferu),
	primary key(id_transferu));
ALTER TABLE Kontrakty
    ADD CONSTRAINT chk_dates CHECK (data_rozpoczecia_kontraktu < data_wygasniecia_kontraktu);
ALTER TABLE Treningi
    ADD CONSTRAINT chk_hours CHECK (godzina_rozpoczecia < godzina_zakonczenia);
ALTER TABLE Zawodnicy
	ADD CONSTRAINT chk_numer_koszulki_integer CHECK (numer_koszulki = TRUNC(numer_koszulki));
ALTER TABLE Zawodnicy
	ADD CONSTRAINT chk_cena_rynkowa_integer CHECK (cena_rynkowa = TRUNC(cena_rynkowa));
ALTER TABLE Kontrakty
	ADD CONSTRAINT chk_wynagrodzenie_miesieczne_integer CHECK (wynagrodzenie_miesieczne = TRUNC(wynagrodzenie_miesieczne));
ALTER TABLE Kontrakty
	ADD CONSTRAINT chk_klauzula_odstepnego_integer CHECK (klauzula_odstepnego = TRUNC(klauzula_odstepnego));
ALTER TABLE Kontrakty
	ADD CONSTRAINT chk_premie_miesieczne_integer CHECK (premie_miesieczne = TRUNC(premie_miesieczne));
ALTER TABLE Obiekty_klubowe
	ADD CONSTRAINT chk_pojemnosc_integer CHECK (pojemnosc = TRUNC(pojemnosc));
ALTER TABLE Obiekty_klubowe
	ADD CONSTRAINT chk_ceny_biletow_integer CHECK (ceny_biletow = TRUNC(ceny_biletow));
ALTER TABLE Mecze
	ADD CONSTRAINT chk_gole_strzelone_integer CHECK (gole_strzelone = TRUNC(gole_strzelone));
ALTER TABLE Mecze
	ADD CONSTRAINT chk_gole_stracone_integer CHECK (gole_stracone = TRUNC(gole_stracone));
ALTER TABLE Statystyki_zawodnikow
	ADD CONSTRAINT chk_liczba_bramek_integer CHECK (liczba_bramek = TRUNC(liczba_bramek));
ALTER TABLE Statystyki_zawodnikow
	ADD CONSTRAINT chk_liczba_asyst_integer CHECK (liczba_asyst = TRUNC(liczba_asyst));
ALTER TABLE Statystyki_zawodnikow
	ADD CONSTRAINT chk_minuty_na_boisku_integer CHECK (minuty_na_boisku = TRUNC(minuty_na_boisku));
ALTER TABLE Statystyki_zawodnikow
	ADD CONSTRAINT chk_procent_celnych_podan_integer CHECK (procent_celnych_podan = TRUNC(procent_celnych_podan));
ALTER TABLE Statystyki_zawodnikow
	ADD CONSTRAINT chk_podania_integer CHECK (podania = TRUNC(podania));
ALTER TABLE Statystyki_zawodnikow
	ADD CONSTRAINT chk_odebrane_pilki_integer CHECK (odebrane_pilki = TRUNC(odebrane_pilki));
ALTER TABLE Statystyki_zawodnikow
	ADD CONSTRAINT chk_liczba_strzalow_integer CHECK (liczba_strzalow = TRUNC(liczba_strzalow));
ALTER TABLE Statystyki_zawodnikow
	ADD CONSTRAINT chk_obronione_strzaly_integer CHECK (obronione_lub_zablokowane_strzaly = TRUNC(obronione_lub_zablokowane_strzaly));
ALTER TABLE Transfery
	ADD CONSTRAINT chk_oplata_transferowa_integer CHECK (oplata_transferowa = TRUNC(oplata_transferowa));
