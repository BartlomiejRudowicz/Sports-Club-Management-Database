CREATE OR REPLACE FUNCTION IS_NUMBER(p_value IN VARCHAR2) RETURN BOOLEAN IS
    v_test NUMBER;
BEGIN
    BEGIN
        v_test := TO_NUMBER(p_value);
        RETURN TRUE;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            RETURN FALSE;
    END;
END;
/
CREATE OR REPLACE FUNCTION SredniaPodanZawodnika (
    p_id_zawodnika NUMBER,
    p_start_sezonu DATE,
    p_koniec_sezonu DATE
) RETURN NUMBER IS
    v_suma_podan NUMBER := 0;
    v_liczba_meczy NUMBER := 0;
    v_srednia NUMBER := 0;
BEGIN
    SELECT 
        ROUND(COALESCE(SUM((sz.procent_celnych_podan / 100) * sz.podania), 0),0), 
        COUNT(DISTINCT m.id_meczu)
    INTO 
        v_suma_podan, 
        v_liczba_meczy
    FROM 
        Statystyki_zawodnikow sz
    JOIN 
        Mecze m ON sz.id_meczu = m.id_meczu
    WHERE 
        sz.id_zawodnika = p_id_zawodnika
        AND m.data_meczu BETWEEN p_start_sezonu AND p_koniec_sezonu;

    IF v_liczba_meczy > 0 THEN
        v_srednia := v_suma_podan / v_liczba_meczy;
    ELSE
        v_srednia := 0;
    END IF;

    RETURN v_srednia;
END;
/
CREATE OR REPLACE FUNCTION ZliczTransferyRok (
    p_rok NUMBER
) RETURN NUMBER IS
    v_liczba_transferow NUMBER := 0;
BEGIN
    SELECT COUNT(*)
    INTO v_liczba_transferow
    FROM Transfery
    WHERE EXTRACT(YEAR FROM data_transferu) = p_rok;

    RETURN v_liczba_transferow;
END;
/

CREATE OR REPLACE FUNCTION ZliczTypPracownika (
    p_typ_pracownika CHAR
) RETURN NUMBER IS
    v_liczba NUMBER := 0;
BEGIN
    SELECT COUNT(*)
    INTO v_liczba
    FROM Pracownicy
    WHERE typ = p_typ_pracownika;

    RETURN v_liczba;
END;
/

CREATE OR REPLACE FUNCTION WynagrodzenieRoczne (
    p_id_pracownika NUMBER
) RETURN NUMBER IS
    v_wynagrodzenie_roczne NUMBER;
BEGIN
    SELECT SUM((wynagrodzenie_miesieczne + NVL(premie_miesieczne, 0)) * 12)
    INTO v_wynagrodzenie_roczne
    FROM Kontrakty
    WHERE id_zakontraktowanego = p_id_pracownika
    AND TO_DATE(SYSDATE, 'DD-MON-YYYY')>=TO_DATE(data_rozpoczecia_kontraktu, 'DD-MON-YYYY')
    AND TO_DATE(SYSDATE, 'DD-MON-YYYY')<=TO_DATE(data_wygasniecia_kontraktu, 'DD-MON-YYYY');

    RETURN v_wynagrodzenie_roczne;
END;
/
CREATE OR REPLACE FUNCTION ObliczLiczbeBramek (
    p_id_zawodnika NUMBER,
    p_data_start DATE,
    p_data_koniec DATE
) RETURN NUMBER IS
    v_liczba_bramek NUMBER := 0;
BEGIN
    -- Obliczanie liczby bramek dla zawodnika w podanym okresie
    SELECT COALESCE(SUM(liczba_bramek), 0)
    INTO v_liczba_bramek
    FROM Statystyki_zawodnikow
    JOIN Mecze ON Statystyki_zawodnikow.id_meczu = Mecze.id_meczu
    WHERE id_zawodnika = p_id_zawodnika
    AND Mecze.data_meczu BETWEEN p_data_start AND p_data_koniec;

    RETURN v_liczba_bramek;
END;
/
CREATE OR REPLACE FUNCTION ObliczLiczbeAsyst (
    p_id_zawodnika NUMBER
) RETURN NUMBER IS
    v_liczba_asyst NUMBER := 0;
BEGIN
    SELECT COALESCE(SUM(liczba_asyst), 0)
    INTO v_liczba_asyst
    FROM Statystyki_zawodnikow
    JOIN Mecze ON Statystyki_zawodnikow.id_meczu = Mecze.id_meczu
    WHERE id_zawodnika = p_id_zawodnika
    AND Mecze.data_meczu >= TO_DATE('15-AUG-2024', 'DD-MON-YYYY')
         AND Mecze.data_meczu <= TO_DATE('30-JUN-2025', 'DD-MON-YYYY');

    RETURN v_liczba_asyst;
END;
/
CREATE OR REPLACE FUNCTION ObliczGoleIAsysty (
    p_id_zawodnika NUMBER
) RETURN NUMBER IS
    v_gole_asysty NUMBER := 0;
BEGIN
    SELECT COALESCE(SUM(liczba_bramek + liczba_asyst), 0)
    INTO v_gole_asysty
    FROM Statystyki_zawodnikow
    JOIN Mecze ON Statystyki_zawodnikow.id_meczu = Mecze.id_meczu
    WHERE id_zawodnika = p_id_zawodnika
    AND Mecze.data_meczu >= TO_DATE('15-AUG-2024', 'DD-MON-YYYY')
         AND Mecze.data_meczu <= TO_DATE('30-JUN-2025', 'DD-MON-YYYY');

    RETURN v_gole_asysty;
END;
/
CREATE OR REPLACE FUNCTION ObliczSredniaPodan (
    p_id_zawodnika NUMBER
) RETURN NUMBER IS
    v_srednia_podan NUMBER := 0;
BEGIN
    SELECT COALESCE(AVG(podania), 0)
    INTO v_srednia_podan
    FROM Statystyki_zawodnikow
    JOIN Mecze ON Statystyki_zawodnikow.id_meczu = Mecze.id_meczu
    WHERE id_zawodnika = p_id_zawodnika
    AND Mecze.data_meczu >= TO_DATE('15-AUG-2024', 'DD-MON-YYYY')
         AND Mecze.data_meczu <= TO_DATE('30-JUN-2025', 'DD-MON-YYYY');

    RETURN v_srednia_podan;
END;
/
CREATE OR REPLACE FUNCTION ObliczCelnePodaniaWMeczu (
    p_id_zawodnika NUMBER
) RETURN NUMBER IS
    v_wynik NUMBER := 0;
BEGIN
    SELECT ROUND(Statystyki_zawodnikow.podania*Statystyki_zawodnikow.procent_celnych_podan,0)
    INTO v_wynik
    FROM Statystyki_zawodnikow
    JOIN Mecze ON Statystyki_zawodnikow.id_meczu = Mecze.id_meczu
    WHERE id_zawodnika = p_id_zawodnika;
    RETURN v_wynik;
END;
/
CREATE OR REPLACE FUNCTION ObliczLiczbeMeczy (
    p_id_zawodnika NUMBER
) RETURN NUMBER IS
    v_liczba_meczy NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_liczba_meczy
    FROM Statystyki_zawodnikow
    JOIN Mecze ON Statystyki_zawodnikow.id_meczu = Mecze.id_meczu
    WHERE id_zawodnika = p_id_zawodnika
    AND Mecze.data_meczu >= TO_DATE('15-AUG-2024', 'DD-MON-YYYY')
         AND Mecze.data_meczu <= TO_DATE('30-JUN-2025', 'DD-MON-YYYY');

    RETURN v_liczba_meczy;
END;
/
CREATE OR REPLACE PROCEDURE DodajPracownika (
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_urodzenia DATE,
    p_typ CHAR,
    p_numer_koszulki IN NUMBER DEFAULT NULL,
    p_pozycja IN VARCHAR2 DEFAULT NULL,
    p_funkcja_boiskowa IN VARCHAR2 DEFAULT NULL,
    p_cena_rynkowa IN NUMBER DEFAULT NULL,
    p_obszar_trenerski IN VARCHAR2 DEFAULT NULL,
    p_rola_zarzadcza IN VARCHAR2 DEFAULT NULL
) IS
    v_id_pracownika NUMBER;
BEGIN
    SELECT generacja_id_pracownika.NEXTVAL INTO v_id_pracownika FROM dual;

    INSERT INTO Pracownicy (id_pracownika, imie, nazwisko, data_urodzenia, typ)
    VALUES (v_id_pracownika, p_imie, p_nazwisko, p_data_urodzenia, p_typ);

    IF p_typ = 'Z' THEN
        INSERT INTO Zawodnicy (id_zawodnika, numer_koszulki, pozycja, funkcja_boiskowa, cena_rynkowa)
        VALUES (v_id_pracownika, p_numer_koszulki, p_pozycja, p_funkcja_boiskowa, p_cena_rynkowa);
    ELSIF p_typ = 'T' THEN
        INSERT INTO Trenerzy (id_trenera, obszar_trenerski)
        VALUES (v_id_pracownika, p_obszar_trenerski);
    ELSIF p_typ = 'C' THEN
        INSERT INTO Czlonkowie_zarzadu (id_czlonka_zarzadu, rola_zarzadcza)
        VALUES (v_id_pracownika, p_rola_zarzadcza);
    END IF;
END;
/
CREATE OR REPLACE PROCEDURE DodajZawodnika (
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_urodzenia DATE,
    p_typ CHAR,
    p_numer_koszulki IN VARCHAR2 DEFAULT NULL,
    p_pozycja IN VARCHAR2 DEFAULT NULL,
    p_funkcja_boiskowa IN VARCHAR2 DEFAULT NULL,
    p_cena_rynkowa IN VARCHAR2 DEFAULT NULL
) IS
    v_id_pracownika NUMBER;
    v_count NUMBER;
    v_count_koszulka NUMBER;
    v_numer_koszulki NUMBER;
    v_cena_rynkowa NUMBER;
BEGIN
    IF p_imie IS NULL THEN
   raise_application_error(-20001, 'Imię jest wymagane!');
   ELSIF LENGTH(p_imie) > 30 THEN
   raise_application_error(-20010, 'Imię nie może przekraczać 30 znaków!');
   ELSIF UPPER(SUBSTR(p_imie, 1, 1)) != SUBSTR(p_imie, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20200, 'Imię musi zaczynać się wielką literą!');
    END IF;
    IF p_nazwisko IS NULL THEN
   raise_application_error(-20002, 'Nazwisko jest wymagane!');
   ELSIF LENGTH(p_nazwisko) > 30 THEN
   raise_application_error(-20011, 'Nazwisko nie może przekraczać 30 znaków!');
   ELSIF UPPER(SUBSTR(p_nazwisko, 1, 1)) != SUBSTR(p_nazwisko, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20201, 'Nazwisko musi zaczynać się wielką literą!');
    END IF;
    IF p_data_urodzenia IS NULL THEN
   raise_application_error(-20003, 'Data urodzenia jest wymagana!');
    END IF;
    IF p_numer_koszulki IS NULL THEN
   raise_application_error(-20004, 'Numer koszulki jest wymagany!');
    END IF;
    IF p_pozycja IS NULL THEN
   raise_application_error(-20005, 'Pozycja jest wymagana!');
    END IF;
    BEGIN
        v_numer_koszulki := TO_NUMBER(p_numer_koszulki);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20150, 'Numer koszulki ma być liczbą!');
    END;
    BEGIN
        v_cena_rynkowa := TO_NUMBER(p_cena_rynkowa);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20151, 'Cena rynkowa ma być liczbą!');
    END;
    IF v_numer_koszulki <= 0 THEN
   raise_application_error(-20006, 'Numer koszulki ma być większy od 0!');
   ELSIF v_numer_koszulki IS NOT NULL AND v_numer_koszulki != TRUNC(v_numer_koszulki) THEN
        raise_application_error(-20015, 'Numer koszulki musi być liczbą całkowitą!');
    ELSIF v_numer_koszulki IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_numer_koszulki))) > 2 THEN
        raise_application_error(-20016, 'Numer koszulki nie może mieć więcej niż 2 cyfry!');
    END IF;
    IF v_cena_rynkowa < 0 THEN
   raise_application_error(-20007, 'Cena rynkowa ma być większa lub równa 0!');
   ELSIF v_cena_rynkowa IS NOT NULL AND v_cena_rynkowa != TRUNC(v_cena_rynkowa) THEN
        raise_application_error(-20014, 'Cena rynkowa musi być liczbą całkowitą!');
    ELSIF v_cena_rynkowa IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_cena_rynkowa))) > 10 THEN
        raise_application_error(-20013, 'Cena rynkowa nie może mieć więcej niż 10 cyfr!');
    END IF;
    IF LENGTH(p_funkcja_boiskowa) > 30 THEN
   raise_application_error(-20012, 'Funkcja boiskowa nie może przekraczać 30 znaków!');
    END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Pracownicy
    WHERE imie = p_imie
      AND nazwisko = p_nazwisko
      AND data_urodzenia = p_data_urodzenia;

    IF v_count > 0 THEN
        raise_application_error(-20008, 'Pracownik z takimi danymi weryfikacyjnymi już istnieje!');
    END IF;

    SELECT COUNT(*)
    INTO v_count_koszulka
    FROM Zawodnicy
    WHERE numer_koszulki = v_numer_koszulki;

    IF v_count_koszulka > 0 THEN
        raise_application_error(-20009, 'Numer koszulki jest już przypisany do innego zawodnika!');
    END IF;
    SELECT generacja_id_pracownika.NEXTVAL INTO v_id_pracownika FROM dual;

    INSERT INTO Pracownicy (id_pracownika, imie, nazwisko, data_urodzenia, typ)
    VALUES (v_id_pracownika, p_imie, p_nazwisko, p_data_urodzenia, p_typ);
    INSERT INTO Zawodnicy (id_zawodnika, numer_koszulki, pozycja, funkcja_boiskowa, cena_rynkowa)
    VALUES (v_id_pracownika, v_numer_koszulki, p_pozycja, p_funkcja_boiskowa, v_cena_rynkowa);
END;
/
CREATE OR REPLACE PROCEDURE DodajTrenera (
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_urodzenia DATE,
    p_typ CHAR,
    p_obszar_trenerski IN VARCHAR2 DEFAULT NULL
) IS
    v_id_pracownika NUMBER;
    v_count NUMBER;
BEGIN
    IF p_imie IS NULL THEN
   raise_application_error(-20001, 'Imię jest wymagane!');
   ELSIF LENGTH(p_imie) > 30 THEN
   raise_application_error(-20007, 'Imię nie może przekraczać 30 znaków!');
   ELSIF UPPER(SUBSTR(p_imie, 1, 1)) != SUBSTR(p_imie, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20200, 'Imię musi zaczynać się wielką literą!');
    END IF;
    IF p_nazwisko IS NULL THEN
   raise_application_error(-20002, 'Nazwisko jest wymagane!');
   ELSIF LENGTH(p_nazwisko) > 30 THEN
   raise_application_error(-20008, 'Nazwisko nie może przekraczać 30 znaków!');
   ELSIF UPPER(SUBSTR(p_nazwisko, 1, 1)) != SUBSTR(p_nazwisko, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20201, 'Nazwisko musi zaczynać się wielką literą!');
    END IF;
    IF p_data_urodzenia IS NULL THEN
   raise_application_error(-20003, 'Data urodzenia jest wymagana!');
    END IF;
    IF p_obszar_trenerski IS NULL THEN
   raise_application_error(-20004, 'Obszar trenerski jest wymagany!');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Pracownicy
    WHERE imie = p_imie
      AND nazwisko = p_nazwisko
      AND data_urodzenia = p_data_urodzenia;

    IF v_count > 0 THEN
        raise_application_error(-20005, 'Pracownik z takimi danymi weryfikacyjnymi już istnieje!');
    END IF;
    SELECT generacja_id_pracownika.NEXTVAL INTO v_id_pracownika FROM dual;

    INSERT INTO Pracownicy (id_pracownika, imie, nazwisko, data_urodzenia, typ)
    VALUES (v_id_pracownika, p_imie, p_nazwisko, p_data_urodzenia, p_typ);
    INSERT INTO Trenerzy (id_trenera, obszar_trenerski)
    VALUES (v_id_pracownika, p_obszar_trenerski);
END;
/
CREATE OR REPLACE PROCEDURE DodajCzlonkaZarzadu (
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_urodzenia DATE,
    p_typ CHAR,
    p_rola_zarzadcza IN VARCHAR2 DEFAULT NULL
) IS
    v_id_pracownika NUMBER;
    v_count NUMBER;
BEGIN
    IF p_imie IS NULL THEN
   raise_application_error(-20001, 'Imię jest wymagane!');
   ELSIF LENGTH(p_imie) > 30 THEN
   raise_application_error(-20007, 'Imię nie może przekraczać 30 znaków!');
   ELSIF UPPER(SUBSTR(p_imie, 1, 1)) != SUBSTR(p_imie, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20200, 'Imię musi zaczynać się wielką literą!');
    END IF;
    IF p_nazwisko IS NULL THEN
   raise_application_error(-20002, 'Nazwisko jest wymagane!');
   ELSIF LENGTH(p_nazwisko) > 30 THEN
   raise_application_error(-20008, 'Nazwisko nie może przekraczać 30 znaków!');
   ELSIF UPPER(SUBSTR(p_nazwisko, 1, 1)) != SUBSTR(p_nazwisko, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20201, 'Imię musi zaczynać się wielką literą!');
    END IF;
    IF p_data_urodzenia IS NULL THEN
   raise_application_error(-20003, 'Data urodzenia jest wymagana!');
    END IF;
    IF p_rola_zarzadcza IS NULL THEN
   raise_application_error(-20004, 'Rola zarządcza jest wymagana!');
    END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Pracownicy
    WHERE imie = p_imie
      AND nazwisko = p_nazwisko
      AND data_urodzenia = p_data_urodzenia;

    IF v_count > 0 THEN
        raise_application_error(-20005, 'Pracownik z takimi danymi weryfikacyjnymi już istnieje!');
    END IF;
    SELECT generacja_id_pracownika.NEXTVAL INTO v_id_pracownika FROM dual;

    INSERT INTO Pracownicy (id_pracownika, imie, nazwisko, data_urodzenia, typ)
    VALUES (v_id_pracownika, p_imie, p_nazwisko, p_data_urodzenia, p_typ);
    INSERT INTO Czlonkowie_zarzadu (id_czlonka_zarzadu, rola_zarzadcza)
    VALUES (v_id_pracownika, p_rola_zarzadcza);
END;
/
CREATE OR REPLACE PROCEDURE DodajTrening (
    p_imie_trenera         VARCHAR2,
    p_nazwisko_trenera     VARCHAR2,
    p_data_urodzenia_trenera DATE,
    p_data_treningu        DATE,
    p_godzina_rozpoczecia VARCHAR2,
    p_godzina_zakonczenia VARCHAR2,
    p_id_obiektu           NUMBER
) IS
    v_id_trener NUMBER;
    v_id_treningu NUMBER;
    v_count NUMBER;
    v_godzina_rozpoczecia TIMESTAMP;
    v_godzina_zakonczenia TIMESTAMP;
BEGIN
    IF p_imie_trenera IS NULL or p_nazwisko_trenera IS NULL or p_data_urodzenia_trenera IS NULL THEN
   raise_application_error(-20001, 'Dane trenera prowadzącego są wymagane!');
    END IF;
    IF p_data_treningu IS NULL THEN
   raise_application_error(-20002, 'Data treningu jest wymagana!');
    END IF;
    IF p_id_obiektu IS NULL THEN
   raise_application_error(-20003, 'Obiekt, na którym odbywa się trening jest wymagany!');
   END IF;
   IF p_godzina_rozpoczecia IS NULL THEN
   raise_application_error(-20050, 'Godzina rozpoczęcia treningu jest wymagana!');
   END IF;
   IF p_godzina_zakonczenia IS NULL THEN
   raise_application_error(-20051, 'Godzina zakończenia treningu jest wymagana!');
   END IF;
   v_godzina_rozpoczecia := TO_TIMESTAMP(p_godzina_rozpoczecia, 'MM/DD/YYYY HH24:MI');
   v_godzina_zakonczenia := TO_TIMESTAMP(p_godzina_zakonczenia, 'MM/DD/YYYY HH24:MI');
   IF TRUNC(v_godzina_rozpoczecia)!=p_data_treningu or TRUNC(v_godzina_zakonczenia)!=p_data_treningu THEN
   raise_application_error(-20053, 'Godziny trwania treningu mają być tego samego dnia co data treningu!');
    END IF;
   IF v_godzina_zakonczenia<v_godzina_rozpoczecia THEN
   raise_application_error(-20052, 'Godzina zakończenia treningu ma być późniejsza niż godzina rozpoczęcia treningu!');
   END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Treningi
    WHERE data_treningu = p_data_treningu and godzina_rozpoczecia=v_godzina_rozpoczecia and godzina_zakonczenia=v_godzina_zakonczenia;

    IF v_count > 0 THEN
        raise_application_error(-20004, 'Podane data oraz godziny treningu są już zajęte!');
    END IF;
    SELECT id_pracownika
    INTO v_id_trener
    FROM Pracownicy
    JOIN Trenerzy ON Pracownicy.id_pracownika = Trenerzy.id_trenera
    WHERE imie = p_imie_trenera 
      AND nazwisko = p_nazwisko_trenera 
      AND data_urodzenia = p_data_urodzenia_trenera;

    SELECT generacja_id_treningu.NEXTVAL 
    INTO v_id_treningu 
    FROM dual;

    INSERT INTO Treningi (
        id_treningu,
        id_trenera_prowadzacego,
        data_treningu,
        godzina_rozpoczecia,
        godzina_zakonczenia,
        id_obiektu_treningowego
    )
    VALUES (
        v_id_treningu,
        v_id_trener,
        p_data_treningu,
        v_godzina_rozpoczecia,
        v_godzina_zakonczenia,
        p_id_obiektu
    );
END;
/
CREATE OR REPLACE PROCEDURE DodajBadanieZdrowotne (
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_urodzenia DATE,
    p_data_badania DATE,
    p_stan_zdrowia VARCHAR2,
    p_poziom_zmeczenia VARCHAR2,
    p_ryzyko_kontuzji VARCHAR2
) IS
    v_id_zawodnika NUMBER;
    v_id_badania NUMBER;
    v_count NUMBER;
BEGIN
    IF p_imie IS NULL or p_nazwisko IS NULL or p_data_urodzenia IS NULL THEN
   raise_application_error(-20001, 'Dane badanego są wymagane!');
    END IF;
    IF p_data_badania IS NULL THEN
   raise_application_error(-20002, 'Data badania jest wymagana!');
    END IF;
    IF p_stan_zdrowia IS NULL THEN
   raise_application_error(-20003, 'Stan zdrowia jest wymagany!');
   ELSIF LENGTH(p_stan_zdrowia) > 150 THEN
   raise_application_error(-20007, 'Opis stanu zdrowia nie może przekraczać 150 znaków!');
    END IF;
    IF p_poziom_zmeczenia IS NULL THEN
   raise_application_error(-20004, 'Poziom zmęczenia jest wymagany!');
    END IF;
    IF p_ryzyko_kontuzji IS NULL THEN
   raise_application_error(-20005, 'Ryzyko kontuzji jest wymagane!');
    END IF;

    SELECT generacja_id_badania.NEXTVAL INTO v_id_badania FROM dual;
    SELECT id_zawodnika INTO v_id_zawodnika
    FROM Pracownicy
    JOIN Zawodnicy ON Pracownicy.id_pracownika = Zawodnicy.id_zawodnika
    WHERE imie = p_imie AND nazwisko = p_nazwisko AND data_urodzenia = p_data_urodzenia;
    SELECT COUNT(*)
    INTO v_count
    FROM Badania_zdrowotne
    WHERE id_badanego = v_id_zawodnika
      AND data_badania = p_data_badania;

    IF v_count > 0 THEN
        raise_application_error(-20006, 'Badanie dla tego zawodnika w tej dacie już istnieje!');
    END IF;
    INSERT INTO Badania_zdrowotne (id_badania, id_badanego, data_badania, stan_zdrowia, poziom_zmeczenia, ryzyko_kontuzji)
    VALUES (v_id_badania, v_id_zawodnika, p_data_badania, p_stan_zdrowia, p_poziom_zmeczenia, p_ryzyko_kontuzji);

END;
/
CREATE OR REPLACE PROCEDURE DodajKontrakt (
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_urodzenia DATE,
    p_data_rozpoczecia DATE,
    p_data_wygasniecia DATE,
    p_wynagrodzenie VARCHAR2,
    p_klauzula VARCHAR2,
    p_premie VARCHAR2
) IS
    v_id_pracownika NUMBER;
    v_id_kontraktu NUMBER;
    v_count NUMBER;
    v_wynagrodzenie NUMBER;
    v_klauzula NUMBER;
    v_premie NUMBER;
BEGIN
    IF p_imie IS NULL or p_nazwisko IS NULL or p_data_urodzenia IS NULL THEN
   raise_application_error(-20001, 'Dane zakontraktowanego są wymagane!');
    END IF;
    IF p_data_rozpoczecia IS NULL THEN
   raise_application_error(-20002, 'Data rozpoczęcia kontraktu jest wymagana!');
    END IF;
    IF p_data_wygasniecia IS NULL THEN
   raise_application_error(-20003, 'Data wygaśnięcia kontraktu jest wymagana!');
    END IF;
    IF p_wynagrodzenie IS NULL THEN
   raise_application_error(-20004, 'Wynagrodzenie miesięczne jest wymagane!');
    END IF;
    IF p_klauzula IS NULL THEN
   raise_application_error(-20005, 'Klauzula odstępnego jest wymagana!');
    END IF;
    BEGIN
        v_wynagrodzenie := TO_NUMBER(p_wynagrodzenie);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20150, 'Wynagrodzenie miesięczne ma być liczbą!');
    END;
    BEGIN
        v_klauzula := TO_NUMBER(p_klauzula);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20151, 'Klauzula odstępnego ma być liczbą!');
    END;
    BEGIN
        v_premie := TO_NUMBER(p_premie);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20152, 'Premia miesięczna ma być liczbą!');
    END;
    IF v_wynagrodzenie < 0 THEN
   raise_application_error(-20006, 'Wynagrodzenie miesięczne ma być większe lub równe 0!');
   ELSIF v_wynagrodzenie IS NOT NULL AND v_wynagrodzenie != TRUNC(v_wynagrodzenie) THEN
        raise_application_error(-20015, 'Wynagrodzenie miesięczne musi być liczbą całkowitą!');
    ELSIF v_wynagrodzenie IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_wynagrodzenie))) > 8 THEN
        raise_application_error(-20016, 'Wynagrodzenie miesięczne nie może mieć więcej niż 8 cyfr!');
    END IF;
    IF v_klauzula < 0 THEN
   raise_application_error(-20007, 'Klauzula odstępnego ma być większa lub równa 0!');
   ELSIF v_klauzula IS NOT NULL AND v_klauzula != TRUNC(v_klauzula) THEN
        raise_application_error(-20017, 'Klauzula odstępnego musi być liczbą całkowitą!');
    ELSIF v_klauzula IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_klauzula))) > 11 THEN
        raise_application_error(-20018, 'Klauzula odstępnego nie może mieć więcej niż 11 cyfr!');
    END IF;
    IF v_premie < 0 THEN
   raise_application_error(-20008, 'Premia miesięczna ma być większa lub równa 0!');
   ELSIF v_premie IS NOT NULL AND v_premie != TRUNC(v_premie) THEN
        raise_application_error(-20019, 'Premia miesięczna musi być liczbą całkowitą!');
    ELSIF v_premie IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_premie))) > 10 THEN
        raise_application_error(-20020, 'Premia miesięczna nie może mieć więcej niż 10 cyfr!');
    END IF;
    IF p_data_rozpoczecia > p_data_wygasniecia THEN
   raise_application_error(-20009, 'Data wygaśnięcia kontraktu ma być późniejsza niż data rozpoczęcia kontraktu!');
    END IF;
    
    SELECT generacja_id_kontraktu.NEXTVAL INTO v_id_kontraktu FROM dual;
    SELECT id_pracownika INTO v_id_pracownika
    FROM Pracownicy
    WHERE imie = p_imie AND nazwisko = p_nazwisko AND data_urodzenia = p_data_urodzenia;

    SELECT COUNT(*)
    INTO v_count
    FROM Kontrakty
    WHERE id_zakontraktowanego = v_id_pracownika
      AND data_rozpoczecia_kontraktu = p_data_rozpoczecia
      AND data_wygasniecia_kontraktu = p_data_wygasniecia;

    IF v_count > 0 THEN
        raise_application_error(-20010, 'Kontrakt dla tego pracownika z podanymi datami już istnieje!');
    END IF;
    INSERT INTO Kontrakty (id_zakontraktowanego, id_kontraktu, data_rozpoczecia_kontraktu, data_wygasniecia_kontraktu, wynagrodzenie_miesieczne, klauzula_odstepnego, premie_miesieczne)
    VALUES (v_id_pracownika, v_id_kontraktu, p_data_rozpoczecia, p_data_wygasniecia, v_wynagrodzenie, v_klauzula, v_premie);

END;
/
CREATE OR REPLACE PROCEDURE DodajObiekt (
    p_nazwa VARCHAR2,
    p_typ VARCHAR2,
    p_pojemnosc VARCHAR2,
    p_lokalizacja VARCHAR2,
    p_ceny_biletow VARCHAR2
) IS
    v_id_obiektu NUMBER;
    v_count NUMBER;
    v_pojemnosc NUMBER;
    v_ceny_biletow NUMBER;
BEGIN

    IF p_nazwa IS NULL THEN
   raise_application_error(-20001, 'Nazwa obiektu jest wymagana!');
   ELSIF LENGTH(p_nazwa) > 60 THEN
   raise_application_error(-20009, 'Nazwa obiektu nie może przekraczać 60 znaków!');
   ELSIF UPPER(SUBSTR(p_nazwa, 1, 1)) != SUBSTR(p_nazwa, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20200, 'Nazwa obiektu musi zaczynać się wielką literą!');
    END IF;
    IF p_typ IS NULL THEN
   raise_application_error(-20002, 'Typ obiektu jest wymagany!');
    END IF;
    IF p_pojemnosc IS NULL THEN
   raise_application_error(-20003, 'Pojemność obiektu jest wymagana!');
    END IF;
    IF p_lokalizacja IS NULL THEN
   raise_application_error(-20004, 'Lokalizacja obiektu jest wymagana!');
   ELSIF LENGTH(p_lokalizacja) > 50 THEN
   raise_application_error(-20008, 'Lokalizacja nie może przekraczać 50 znaków!');
    END IF;
    BEGIN
        v_pojemnosc := TO_NUMBER(p_pojemnosc);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20150, 'Pojemność obiektu ma być liczbą!');
    END;
    BEGIN
        v_ceny_biletow := TO_NUMBER(p_ceny_biletow);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20151, 'Cena biletów ma być liczbą!');
    END;
    IF v_pojemnosc < 0 THEN
   raise_application_error(-20005, 'Pojemność obiektu ma być większa lub równa 0!');
   ELSIF v_pojemnosc IS NOT NULL AND v_pojemnosc != TRUNC(v_pojemnosc) THEN
        raise_application_error(-20015, 'Pojemność obiektu musi być liczbą całkowitą!');
    ELSIF v_pojemnosc IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_pojemnosc))) > 6 THEN
        raise_application_error(-20016, 'Pojemność obiektu nie może mieć więcej niż 6 cyfr!');
    END IF;
    IF v_ceny_biletow < 0 THEN
   raise_application_error(-20006, 'Ceny biletów mają być większe lub równe 0!');
   ELSIF v_ceny_biletow IS NOT NULL AND v_ceny_biletow != TRUNC(v_ceny_biletow) THEN
        raise_application_error(-20017, 'Ceny biletów muszą być liczbą całkowitą!');
    ELSIF v_ceny_biletow IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_ceny_biletow))) > 6 THEN
        raise_application_error(-20018, 'Ceny biletów nie mogą mieć więcej niż 6 cyfr!');
    END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Obiekty_klubowe
    WHERE nazwa_obiektu = p_nazwa;

    IF v_count > 0 THEN
        raise_application_error(-20007, 'Obiekt o podanej nazwie już istnieje!');
    END IF;
    SELECT generacja_id_obiektu.NEXTVAL INTO v_id_obiektu FROM dual;
    INSERT INTO Obiekty_klubowe (id_obiektu, nazwa_obiektu, typ_obiektu, pojemnosc, lokalizacja, ceny_biletow)
    VALUES (v_id_obiektu, p_nazwa, p_typ, v_pojemnosc, p_lokalizacja, v_ceny_biletow);
END;
/
CREATE OR REPLACE PROCEDURE DodajTransfer (
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_urodzenia DATE,
    p_data_transferu DATE,
    p_typ_transferu VARCHAR2,
    p_oplata_transferowa VARCHAR2
) IS
    v_id_pracownika NUMBER;
    v_id_transferu NUMBER;
    v_count NUMBER;
    v_oplata_transferowa NUMBER;
BEGIN
    IF p_imie IS NULL or p_nazwisko IS NULL or p_data_urodzenia IS NULL THEN
   raise_application_error(-20001, 'Dane transferowanego są wymagane!');
    END IF;
    IF p_data_transferu IS NULL THEN
   raise_application_error(-20002, 'Data transferu jest wymagana!');
    END IF;
    IF p_typ_transferu IS NULL THEN
   raise_application_error(-20003, 'Typ transferu jest wymagany!');
    END IF;
    IF p_oplata_transferowa IS NULL THEN
   raise_application_error(-20004, 'Opłata transferowa jest wymagana!');
    END IF;
    BEGIN
        v_oplata_transferowa := TO_NUMBER(p_oplata_transferowa);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20150, 'Opłata transferowa ma być liczbą!');
    END;
    IF v_oplata_transferowa < 0 THEN
   raise_application_error(-20005, 'Opłata transferowa ma być większa lub równa 0!');
   ELSIF v_oplata_transferowa IS NOT NULL AND v_oplata_transferowa != TRUNC(v_oplata_transferowa) THEN
        raise_application_error(-20015, 'Opłata transferowa musi być liczbą całkowitą!');
    ELSIF v_oplata_transferowa IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_oplata_transferowa))) > 11 THEN
        raise_application_error(-20016, 'Opłata transferowa nie może mieć więcej niż 11 cyfr!');
    END IF;
    SELECT generacja_id_transferu.NEXTVAL INTO v_id_transferu FROM dual;
    SELECT id_pracownika INTO v_id_pracownika
    FROM Pracownicy
    WHERE imie = p_imie AND nazwisko = p_nazwisko AND data_urodzenia = p_data_urodzenia;
    SELECT COUNT(*)
    INTO v_count
    FROM Transfery
    WHERE id_transferowanego = v_id_pracownika
      AND data_transferu = p_data_transferu;

    IF v_count > 0 THEN
        raise_application_error(-20006, 'Transfer dla tego zawodnika w tej dacie już istnieje!');
    END IF;
    INSERT INTO Transfery (id_transferowanego, id_transferu, data_transferu, typ_transferu, oplata_transferowa)
    VALUES (v_id_pracownika, v_id_transferu, p_data_transferu, p_typ_transferu, v_oplata_transferowa);

END;
/
CREATE OR REPLACE PROCEDURE DodajMecz (
    p_przeciwnik VARCHAR2,
    p_data_meczu DATE,
    p_typ_rozgrywek VARCHAR2,
    p_status_meczu VARCHAR2,
    p_typ_meczu CHAR,
    p_gole_strzelone VARCHAR2,
    p_gole_stracone VARCHAR2,
    p_id_obiektu_meczowego NUMBER DEFAULT NULL,
    p_stadion_wyjazdowy VARCHAR2 DEFAULT NULL
) IS
    v_id_meczu NUMBER;
    v_count NUMBER;
    v_gole_strzelone NUMBER;
    v_gole_stracone NUMBER;
BEGIN
    IF p_przeciwnik IS NULL THEN
   raise_application_error(-20001, 'Przeciwnik jest wymagany!');
   ELSIF LENGTH(p_przeciwnik) > 50 THEN
   raise_application_error(-20011, 'Przeciwnik nie może mieć dłuższej nazwy niż 50 znaków!');
   ELSIF UPPER(SUBSTR(p_przeciwnik, 1, 1)) != SUBSTR(p_przeciwnik, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20200, 'Przeciwnik musi zaczynać się wielką literą!');
    END IF;
    IF p_data_meczu IS NULL THEN
   raise_application_error(-20002, 'Data meczu jest wymagana!');
    END IF;
    IF p_typ_rozgrywek IS NULL THEN
   raise_application_error(-20003, 'Typ rozgrywek jest wymagany!');
    END IF;
    IF p_status_meczu IS NULL THEN
   raise_application_error(-20004, 'Status meczu jest wymagany!');
    END IF;
    IF p_typ_meczu IS NULL THEN
   raise_application_error(-20005, 'Typ meczu jest wymagany!');
    END IF;
    IF p_id_obiektu_meczowego IS NULL AND p_typ_meczu='D' THEN
   raise_application_error(-20006, 'Obiekt meczowy dla meczu domowego jest wymagany!');
    END IF;
    IF p_stadion_wyjazdowy IS NULL AND p_typ_meczu='W' THEN
   raise_application_error(-20007, 'Obiekt meczowy dla meczu wyjazdowego jest wymagany!');
   ELSIF LENGTH(p_stadion_wyjazdowy) > 60 AND p_typ_meczu='W' THEN
   raise_application_error(-20012, 'Stadion wyjazdowy nie może mieć dłuższej nazwy niż 60 znaków!');
   ELSIF UPPER(SUBSTR(p_stadion_wyjazdowy, 1, 1)) != SUBSTR(p_stadion_wyjazdowy, 1, 1) AND p_typ_meczu='W' THEN
        RAISE_APPLICATION_ERROR(-20201, 'Nazwa stadionu wyjazdowego musi zaczynać się wielką literą!');
    END IF;
    BEGIN
        v_gole_strzelone := TO_NUMBER(p_gole_strzelone);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20150, 'Gole strzelone mają być liczbą!');
    END;
    BEGIN
        v_gole_stracone := TO_NUMBER(p_gole_stracone);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20151, 'Gole stracone mają być liczbą!');
    END;
    IF p_status_meczu != 'Rozegrany' and (v_gole_strzelone IS NOT NULL OR v_gole_stracone IS NOT NULL) THEN
            RAISE_APPLICATION_ERROR(-20020, 'Jeśli mecz nie jest rozegrany, gole strzelone i stracone muszą być puste!');
    END IF;
    IF v_gole_strzelone < 0 THEN
   raise_application_error(-20008, 'Liczba goli strzelonych ma być większa lub równa 0!');
   ELSIF v_gole_strzelone IS NOT NULL AND v_gole_strzelone != TRUNC(v_gole_strzelone) THEN
        raise_application_error(-20015, 'Liczba goli strzelonych musi być liczbą całkowitą!');
    ELSIF v_gole_strzelone IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_gole_strzelone))) > 3 THEN
        raise_application_error(-20016, 'Liczba goli strzelonych nie może mieć więcej niż 3 cyfry!');
    END IF;
    IF v_gole_stracone < 0 THEN
   raise_application_error(-20009, 'Liczba goli straconych ma być większa lub równa 0!');
   ELSIF v_gole_stracone IS NOT NULL AND v_gole_stracone != TRUNC(v_gole_stracone) THEN
        raise_application_error(-20017, 'Liczba goli straconych musi być liczbą całkowitą!');
    ELSIF v_gole_stracone IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_gole_stracone))) > 3 THEN
        raise_application_error(-20018, 'Liczba goli straconych nie może mieć więcej niż 3 cyfry!');
    END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Mecze
    WHERE data_meczu = p_data_meczu;

    IF v_count > 0 THEN
        raise_application_error(-20010, 'Podana data meczu jest już zajęta!');
    END IF;
    SELECT generacja_id_meczu.NEXTVAL INTO v_id_meczu FROM dual;
    INSERT INTO Mecze (id_meczu, data_meczu, przeciwnik, typ_rozgrywek, status_meczu, gole_strzelone, gole_stracone, typ_meczu)
    VALUES (v_id_meczu, p_data_meczu, p_przeciwnik, p_typ_rozgrywek, p_status_meczu, v_gole_strzelone, v_gole_stracone, p_typ_meczu);

    IF p_typ_meczu = 'D' THEN
        INSERT INTO Mecze_domowe (id_meczu_domowego, id_obiektu_meczowego)
        VALUES (v_id_meczu, p_id_obiektu_meczowego);
    ELSIF p_typ_meczu = 'W' THEN
        INSERT INTO Mecze_wyjazdowe (id_meczu_wyjazdowego, stadion_wyjazdowy)
        VALUES (v_id_meczu, p_stadion_wyjazdowy);
    END IF;
END;
/
CREATE OR REPLACE PROCEDURE DodajUczestnikaDoTreningu (
    p_imie IN VARCHAR2,
    p_nazwisko IN VARCHAR2,
    p_data_urodzenia IN DATE,
    p_id_treningu      IN NUMBER,
    p_czy_indywidualny IN CHAR,
    p_grupa_treningowa IN VARCHAR2
) IS
    v_id_zawodnika NUMBER;
    v_id_uczestnictwa NUMBER;
    v_count NUMBER;
BEGIN
    IF p_imie IS NULL or p_nazwisko IS NULL or p_data_urodzenia IS NULL THEN
   raise_application_error(-20001, 'Dane uczestnika treningu są wymagane!');
    END IF;
    IF p_id_treningu IS NULL THEN
   raise_application_error(-20002, 'Dane treningu są wymagane!');
    END IF;
    IF p_czy_indywidualny IS NULL THEN
   raise_application_error(-20003, 'Typ treningu jest wymagany!');
    END IF;
    IF p_grupa_treningowa IS NULL THEN
   raise_application_error(-20004, 'Grupa treningowa jest wymagana!');
   END IF;

    SELECT generacja_id_uczestnictwa.NEXTVAL INTO v_id_uczestnictwa FROM dual;
    -- Pobranie ID zawodnika na podstawie danych osobowych
    SELECT z.id_zawodnika
    INTO v_id_zawodnika
    FROM Zawodnicy z
    INNER JOIN Pracownicy p ON z.id_zawodnika = p.id_pracownika
    WHERE p.imie = p_imie
      AND p.nazwisko = p_nazwisko
      AND p.data_urodzenia = p_data_urodzenia;

    SELECT COUNT(*)
    INTO v_count
    FROM Uczestnicy_treningow
    WHERE id_treningu = p_id_treningu
      AND id_zawodnika = v_id_zawodnika;

    IF v_count > 0 THEN
        raise_application_error(-20005, 'Uczestnik jest już przypisany do tego treningu!');
    END IF;

    INSERT INTO Uczestnicy_treningow (id_uczestnictwa, id_zawodnika, id_treningu, czy_indywidualny, grupa_treningowa)
    VALUES (v_id_uczestnictwa, v_id_zawodnika, p_id_treningu, p_czy_indywidualny, p_grupa_treningowa);
END;
/
CREATE OR REPLACE PROCEDURE UsunTransfery (p_id_transferu NUMBER) IS
BEGIN
    DELETE FROM Transfery
    WHERE p_id_transferu=id_transferu;
END;
/
CREATE OR REPLACE PROCEDURE UsunKontrakty (p_id_kontraktu NUMBER) IS
BEGIN
    DELETE FROM Kontrakty
    WHERE p_id_kontraktu=id_kontraktu;
END;
/
CREATE OR REPLACE PROCEDURE UsunBadaniaZdrowotne (p_id_badania NUMBER) IS
BEGIN
    DELETE FROM Badania_zdrowotne
    WHERE id_badania = p_id_badania;
END;
/
CREATE OR REPLACE PROCEDURE UsunZawodnikow (p_imie VARCHAR2, p_nazwisko VARCHAR2, p_data_urodzenia DATE) IS
BEGIN
    DELETE FROM Zawodnicy
    WHERE id_zawodnika IN (
        SELECT id_pracownika
        FROM Pracownicy
        WHERE imie = p_imie AND nazwisko = p_nazwisko AND data_urodzenia = p_data_urodzenia AND typ = 'Z'
    );
END;
/
CREATE OR REPLACE PROCEDURE UsunTrenerow (p_imie VARCHAR2, p_nazwisko VARCHAR2, p_data_urodzenia DATE) IS
BEGIN
    DELETE FROM Trenerzy
    WHERE id_trenera IN (
        SELECT id_pracownika
        FROM Pracownicy
        WHERE imie = p_imie AND nazwisko = p_nazwisko AND data_urodzenia = p_data_urodzenia AND typ = 'T'
    );
END;
/
CREATE OR REPLACE PROCEDURE UsunCzlonkowZarzadu (p_imie VARCHAR2, p_nazwisko VARCHAR2, p_data_urodzenia DATE) IS
BEGIN
    DELETE FROM Czlonkowie_zarzadu
    WHERE id_czlonka_zarzadu IN (
        SELECT id_pracownika
        FROM Pracownicy
        WHERE imie = p_imie AND nazwisko = p_nazwisko AND data_urodzenia = p_data_urodzenia AND typ = 'C'
    );
END;
/
CREATE OR REPLACE PROCEDURE UsunPracownika (
    p_id NUMBER
) IS
    v_typ_pracownika CHAR(1);
BEGIN
    -- Pobierz typ pracownika na podstawie ID
    SELECT typ
    INTO v_typ_pracownika
    FROM Pracownicy
    WHERE id_pracownika = p_id;

    BEGIN
        DELETE FROM Pracownicy
        WHERE id_pracownika = p_id;

        IF SQL%ROWCOUNT = 0 THEN
            raise_application_error(-20001, 'Pracownik o podanym ID nie istnieje!');
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -2292 THEN
                CASE v_typ_pracownika
                    WHEN 'Z' THEN
                        raise_application_error(-20002, 'Nie możesz usunąć tego zawodnika, ponieważ ma powiązane rekordy w innych tabelach.');
                    WHEN 'T' THEN
                        raise_application_error(-20003, 'Nie możesz usunąć tego trenera, ponieważ ma powiązane rekordy w innych tabelach.');
                    WHEN 'C' THEN
                        raise_application_error(-20004, 'Nie możesz usunąć tego członka zarządu, ponieważ ma powiązane rekordy w innych tabelach.');
                    ELSE
                        raise_application_error(-20005, 'Nie można usunąć pracownika. Wystąpił problem z powiązanymi rekordami.');
                END CASE;
            ELSE
                raise_application_error(-20006, 'Wystąpił nieoczekiwany błąd: ' || SQLERRM);
            END IF;
    END;
END;
/
CREATE OR REPLACE FUNCTION my_error_handling_function (
    p_error IN apex_error.t_error )
    RETURN apex_error.t_error_result
IS
    l_result   apex_error.t_error_result;
    l_pos      PLS_INTEGER;
BEGIN
    l_result.message := p_error.message; 
    l_result.additional_info := p_error.additional_info; 
    l_result.display_location := p_error.display_location; 
    l_result.page_item_name := p_error.page_item_name;
    IF p_error.is_internal_error THEN
        l_pos := INSTR(l_result.message, 'Ajax call returned server error');
        IF l_pos > 0 THEN
            l_pos := INSTR(l_result.message, 'ORA-');
            IF l_pos > 0 THEN
                l_result.message := SUBSTR(l_result.message, l_pos + 10);
            END IF;
            l_pos := INSTR(l_result.message, 'for Execute Server-Side Code');
            IF l_pos > 0 THEN
                l_result.message := SUBSTR(l_result.message, 1, l_pos - 1);
            END IF;
            l_result.message := TRIM(l_result.message);
        END IF;
    END IF;

    RETURN l_result;
END my_error_handling_function;
/
CREATE OR REPLACE PROCEDURE UsunObiektyKlubowe (p_id_obiektu NUMBER) IS
BEGIN
    BEGIN
        -- Próbujemy usunąć obiekt klubowy
        DELETE FROM Obiekty_klubowe
        WHERE id_obiektu = p_id_obiektu;

        -- Sprawdzenie, czy rekord został usunięty
        IF SQL%ROWCOUNT = 0 THEN
            raise_application_error(-20001, 'Obiekt klubowy o podanym ID nie istnieje!');
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- Sprawdzenie, czy błąd to naruszenie klucza obcego
            IF SQLCODE = -2292 THEN
                raise_application_error(-20002, 'Nie można usunąć obiektu klubowego, ponieważ jest powiązany z rekordami w innych tabelach.');
            ELSE
                -- Inne błędy
                raise_application_error(-20003, 'Wystąpił nieoczekiwany błąd: ' || SQLERRM);
            END IF;
    END;
END;
/
CREATE OR REPLACE PROCEDURE UsunTrening (p_id_treningu NUMBER) IS
BEGIN
    BEGIN
        -- Próbujemy usunąć rekord z tabeli Treningi
        DELETE FROM Treningi
        WHERE id_treningu = p_id_treningu;

        -- Sprawdzenie, czy rekord został usunięty
        IF SQL%ROWCOUNT = 0 THEN
            raise_application_error(-20001, 'Trening o podanym ID nie istnieje!');
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- Sprawdzenie, czy błąd to naruszenie klucza obcego
            IF SQLCODE = -2292 THEN
                raise_application_error(-20002, 'Nie można usunąć treningu, ponieważ jest powiązany z uczestnikami tego treningu.');
            ELSE
                -- Obsługa innych błędów
                raise_application_error(-20003, 'Wystąpił nieoczekiwany błąd: ' || SQLERRM);
            END IF;
    END;
END;
/

CREATE OR REPLACE PROCEDURE UsunUczestnikaTreningu (p_id_uczestnictwa NUMBER) IS
BEGIN
    DELETE FROM Uczestnicy_treningow
    WHERE id_uczestnictwa = p_id_uczestnictwa;
END;
/
CREATE OR REPLACE PROCEDURE UsunMecze (p_id_meczu NUMBER) IS
BEGIN
    BEGIN
        -- Usuń powiązany rekord z tabeli Mecze_domowe, jeśli istnieje
        DELETE FROM Mecze_domowe
        WHERE id_meczu_domowego = p_id_meczu;

        -- Usuń powiązany rekord z tabeli Mecze_wyjazdowe, jeśli istnieje
        DELETE FROM Mecze_wyjazdowe
        WHERE id_meczu_wyjazdowego = p_id_meczu;

        -- Usuń rekord z tabeli Mecze
        DELETE FROM Mecze
        WHERE id_meczu = p_id_meczu;

        -- Sprawdzenie, czy rekord został usunięty
        IF SQL%ROWCOUNT = 0 THEN
            raise_application_error(-20001, 'Mecz o podanym ID nie istnieje!');
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- Sprawdzenie, czy błąd to naruszenie klucza obcego
            IF SQLCODE = -2292 THEN
                raise_application_error(-20002, 'Nie można usunąć meczu, ponieważ jest powiązany ze statystykami zawodników z tego meczu.');
            ELSE
                -- Obsługa innych błędów
                raise_application_error(-20003, 'Wystąpił nieoczekiwany błąd: ' || SQLERRM);
            END IF;
    END;
END;
/
CREATE OR REPLACE PROCEDURE aktualizuj_dane_zawodnika (
    p_id_pracownika      IN  NUMBER,
    p_imie               IN  VARCHAR2,
    p_nazwisko           IN  VARCHAR2,
    p_data_urodzenia     IN  DATE,
    p_numer_koszulki     IN  VARCHAR2,
    p_pozycja            IN  VARCHAR2,
    p_funkcja_boiskowa   IN  VARCHAR2,
    p_cena_rynkowa       IN  VARCHAR2
)
IS
    v_count NUMBER;
    v_count_koszulka NUMBER;
    v_numer_koszulki NUMBER;
    v_cena_rynkowa NUMBER;
BEGIN

    IF p_imie IS NULL THEN
   raise_application_error(-20001, 'Imię jest wymagane!');
   ELSIF LENGTH(p_imie) > 30 THEN
   raise_application_error(-20010, 'Imię nie może przekraczać 30 znaków!');
   ELSIF UPPER(SUBSTR(p_imie, 1, 1)) != SUBSTR(p_imie, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20200, 'Imię musi zaczynać się wielką literą!');
    END IF;
    IF p_nazwisko IS NULL THEN
   raise_application_error(-20002, 'Nazwisko jest wymagane!');
   ELSIF LENGTH(p_nazwisko) > 30 THEN
   raise_application_error(-20011, 'Nazwisko nie może przekraczać 30 znaków!');
   ELSIF UPPER(SUBSTR(p_nazwisko, 1, 1)) != SUBSTR(p_nazwisko, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20201, 'Nazwisko musi zaczynać się wielką literą!');
    END IF;
    IF p_data_urodzenia IS NULL THEN
   raise_application_error(-20003, 'Data urodzenia jest wymagana!');
    END IF;
    IF p_numer_koszulki IS NULL THEN
   raise_application_error(-20004, 'Numer koszulki jest wymagany!');
    END IF;
    IF p_pozycja IS NULL THEN
   raise_application_error(-20005, 'Pozycja jest wymagana!');
    END IF;
    BEGIN
        v_numer_koszulki := TO_NUMBER(p_numer_koszulki);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20150, 'Numer koszulki ma być liczbą!');
    END;
    BEGIN
        v_cena_rynkowa := TO_NUMBER(p_cena_rynkowa);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20151, 'Cena rynkowa ma być liczbą!');
    END;
    IF v_numer_koszulki <= 0 THEN
   raise_application_error(-20006, 'Numer koszulki ma być większy od 0!');
   ELSIF v_numer_koszulki IS NOT NULL AND v_numer_koszulki != TRUNC(v_numer_koszulki) THEN
        raise_application_error(-20015, 'Numer koszulki musi być liczbą całkowitą!');
    ELSIF v_numer_koszulki IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_numer_koszulki))) > 2 THEN
        raise_application_error(-20016, 'Numer koszulki nie może mieć więcej niż 2 cyfry!');
    END IF;
    IF v_cena_rynkowa < 0 THEN
   raise_application_error(-20007, 'Cena rynkowa ma być większa lub równa 0!');
   ELSIF v_cena_rynkowa IS NOT NULL AND v_cena_rynkowa != TRUNC(v_cena_rynkowa) THEN
        raise_application_error(-20014, 'Cena rynkowa musi być liczbą całkowitą!');
    ELSIF v_cena_rynkowa IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_cena_rynkowa))) > 10 THEN
        raise_application_error(-20013, 'Cena rynkowa nie może mieć więcej niż 10 cyfr!');
    END IF;
    IF LENGTH(p_funkcja_boiskowa) > 30 THEN
   raise_application_error(-20012, 'Funkcja boiskowa nie może przekraczać 30 znaków!');
    END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Pracownicy
    WHERE imie = p_imie
      AND nazwisko = p_nazwisko
      AND data_urodzenia = p_data_urodzenia
      AND id_pracownika != p_id_pracownika;

    IF v_count > 0 THEN
        raise_application_error(-20008, 'Pracownik z takimi danymi weryfikacyjnymi już istnieje!');
    END IF;

    SELECT COUNT(*)
    INTO v_count_koszulka
    FROM Zawodnicy
    WHERE numer_koszulki = v_numer_koszulki
      AND id_zawodnika != p_id_pracownika;

    IF v_count_koszulka > 0 THEN
        raise_application_error(-20009, 'Numer koszulki jest już przypisany do innego zawodnika!');
    END IF;

    -- Aktualizacja danych w tabeli Pracownicy
    UPDATE Pracownicy
       SET imie = p_imie,
           nazwisko = p_nazwisko,
           data_urodzenia = p_data_urodzenia
     WHERE id_pracownika = p_id_pracownika;

    -- Aktualizacja danych w tabeli Zawodnicy
    UPDATE Zawodnicy
       SET numer_koszulki    = v_numer_koszulki,
           pozycja           = p_pozycja,
           funkcja_boiskowa  = p_funkcja_boiskowa,
           cena_rynkowa      = v_cena_rynkowa
     WHERE id_zawodnika = p_id_pracownika;
END aktualizuj_dane_zawodnika;
/
CREATE OR REPLACE PROCEDURE AktualizujKontrakt (
    p_id_kontraktu NUMBER,
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_urodzenia DATE,
    p_data_rozpoczecia DATE,
    p_data_wygasniecia DATE,
    p_wynagrodzenie VARCHAR2,
    p_klauzula VARCHAR2,
    p_premie VARCHAR2
) IS
    v_id_pracownika NUMBER;
    v_count NUMBER;
    v_wynagrodzenie NUMBER;
    v_klauzula NUMBER;
    v_premie NUMBER;
BEGIN
    IF p_imie IS NULL or p_nazwisko IS NULL or p_data_urodzenia IS NULL THEN
   raise_application_error(-20001, 'Dane zakontraktowanego są wymagane!');
    END IF;
    IF p_data_rozpoczecia IS NULL THEN
   raise_application_error(-20002, 'Data rozpoczęcia kontraktu jest wymagana!');
    END IF;
    IF p_data_wygasniecia IS NULL THEN
   raise_application_error(-20003, 'Data wygaśnięcia kontraktu jest wymagana!');
    END IF;
    IF p_wynagrodzenie IS NULL THEN
   raise_application_error(-20004, 'Wynagrodzenie miesięczne jest wymagane!');
    END IF;
    IF p_klauzula IS NULL THEN
   raise_application_error(-20005, 'Klauzula odstępnego jest wymagana!');
    END IF;
    BEGIN
        v_wynagrodzenie := TO_NUMBER(p_wynagrodzenie);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20150, 'Wynagrodzenie miesięczne ma być liczbą!');
    END;
    BEGIN
        v_klauzula := TO_NUMBER(p_klauzula);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20151, 'Klauzula odstępnego ma być liczbą!');
    END;
    BEGIN
        v_premie := TO_NUMBER(p_premie);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20152, 'Premia miesięczna ma być liczbą!');
    END;
    IF v_wynagrodzenie < 0 THEN
   raise_application_error(-20006, 'Wynagrodzenie miesięczne ma być większe lub równe 0!');
   ELSIF v_wynagrodzenie IS NOT NULL AND v_wynagrodzenie != TRUNC(v_wynagrodzenie) THEN
        raise_application_error(-20015, 'Wynagrodzenie miesięczne musi być liczbą całkowitą!');
    ELSIF v_wynagrodzenie IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_wynagrodzenie))) > 8 THEN
        raise_application_error(-20016, 'Wynagrodzenie miesięczne nie może mieć więcej niż 8 cyfr!');
    END IF;
    IF v_klauzula < 0 THEN
   raise_application_error(-20007, 'Klauzula odstępnego ma być większa lub równa 0!');
   ELSIF v_klauzula IS NOT NULL AND v_klauzula != TRUNC(v_klauzula) THEN
        raise_application_error(-20017, 'Klauzula odstępnego musi być liczbą całkowitą!');
    ELSIF v_klauzula IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_klauzula))) > 11 THEN
        raise_application_error(-20018, 'Klauzula odstępnego nie może mieć więcej niż 11 cyfr!');
    END IF;
    IF v_premie < 0 THEN
   raise_application_error(-20008, 'Premia miesięczna ma być większa lub równa 0!');
   ELSIF v_premie IS NOT NULL AND v_premie != TRUNC(v_premie) THEN
        raise_application_error(-20019, 'Premia miesięczna musi być liczbą całkowitą!');
    ELSIF v_premie IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_premie))) > 10 THEN
        raise_application_error(-20020, 'Premia miesięczna nie może mieć więcej niż 10 cyfr!');
    END IF;
    IF p_data_rozpoczecia > p_data_wygasniecia THEN
   raise_application_error(-20009, 'Data wygaśnięcia kontraktu ma być późniejsza niż data rozpoczęcia kontraktu!');
    END IF;
    -- Wyszukaj id_pracownika na podstawie imienia, nazwiska i daty urodzenia
    SELECT id_pracownika
    INTO v_id_pracownika
    FROM Pracownicy
    WHERE imie = p_imie
      AND nazwisko = p_nazwisko
      AND data_urodzenia = p_data_urodzenia;

    SELECT COUNT(*)
    INTO v_count
    FROM Kontrakty
    WHERE id_zakontraktowanego = v_id_pracownika
      AND data_rozpoczecia_kontraktu = p_data_rozpoczecia
      AND data_wygasniecia_kontraktu = p_data_wygasniecia
      AND id_kontraktu != p_id_kontraktu;

    IF v_count > 0 THEN
        raise_application_error(-20010, 'Kontrakt dla tego pracownika z podanymi datami już istnieje!');
    END IF;
    -- Zaktualizuj kontrakt w tabeli
    UPDATE Kontrakty
    SET id_zakontraktowanego = v_id_pracownika,
        data_rozpoczecia_kontraktu = p_data_rozpoczecia,
        data_wygasniecia_kontraktu = p_data_wygasniecia,
        wynagrodzenie_miesieczne = v_wynagrodzenie,
        klauzula_odstepnego = v_klauzula,
        premie_miesieczne = v_premie
    WHERE id_kontraktu = p_id_kontraktu;
END;
/
CREATE OR REPLACE PROCEDURE DodajStatystykiZawodnika (
    p_data_meczu DATE,
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_urodzenia DATE,
    p_liczba_bramek VARCHAR2,
    p_liczba_asyst VARCHAR2,
    p_minuty_na_boisku VARCHAR2,
    p_procent_celnych_podan VARCHAR2,
    p_podania VARCHAR2,
    p_odebrane_pilki VARCHAR2,
    p_liczba_strzalow VARCHAR2,
    p_obronione_lub_zablokowane_strzaly VARCHAR2
) IS
    v_id_meczu NUMBER;
    v_id_zawodnika NUMBER;
    v_id_statystyk NUMBER;
    v_count NUMBER;
    v_liczba_bramek NUMBER;
    v_liczba_asyst NUMBER;
    v_minuty_na_boisku NUMBER;
    v_procent_celnych_podan NUMBER;
    v_podania NUMBER;
    v_odebrane_pilki NUMBER;
    v_liczba_strzalow NUMBER;
    v_obronione_lub_zablokowane_strzaly NUMBER;
    v_status_meczu VARCHAR2(30);

BEGIN
    IF p_imie IS NULL or p_nazwisko IS NULL or p_data_urodzenia IS NULL THEN
   raise_application_error(-20001, 'Dane uczestnika meczu są wymagane!');
    END IF;
    IF p_data_meczu IS NULL THEN
   raise_application_error(-20002, 'Data meczu jest wymagana!');
    END IF;
    IF p_liczba_bramek IS NULL THEN
   raise_application_error(-20003, 'Liczba strzelonych bramek jest wymagana!');
    END IF;
    IF p_liczba_asyst IS NULL THEN
   raise_application_error(-20004, 'Liczba zdobytych asyst jest wymagana!');
    END IF;
    IF p_minuty_na_boisku IS NULL THEN
   raise_application_error(-20005, 'Liczba minut na boisku jest wymagana!');
    END IF;
    IF p_procent_celnych_podan IS NULL THEN
   raise_application_error(-20006, 'Procent celnych podań jest wymagany!');
    END IF;
    IF p_podania IS NULL THEN
   raise_application_error(-20007, 'Liczba podań jest wymagana!');
    END IF;
    IF p_odebrane_pilki IS NULL THEN
   raise_application_error(-20008, 'Liczba odebranych piłek jest wymagana!');
    END IF;
    IF p_liczba_strzalow IS NULL THEN
   raise_application_error(-20009, 'Liczba strzałów jest wymagana!');
    END IF;
    IF p_obronione_lub_zablokowane_strzaly IS NULL THEN
   raise_application_error(-20010, 'Liczba obronionych lub zablokowanych strzałów jest wymagana!');
    END IF;
    BEGIN
        v_liczba_bramek := TO_NUMBER(p_liczba_bramek);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20150, 'Liczba bramek ma być liczbą!');
    END;
    BEGIN
        v_liczba_asyst := TO_NUMBER(p_liczba_asyst);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20151, 'Liczba asyst ma być liczbą!');
    END;
    BEGIN
        v_minuty_na_boisku := TO_NUMBER(p_minuty_na_boisku);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20152, 'Liczba minut na boisku ma być liczbą!');
    END;
    BEGIN
        v_procent_celnych_podan := TO_NUMBER(p_procent_celnych_podan);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20153, 'Procent celnych podań ma być liczbą!');
    END;
    BEGIN
        v_podania := TO_NUMBER(p_podania);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20154, 'Liczba podań ma być liczbą!');
    END;
    BEGIN
        v_odebrane_pilki := TO_NUMBER(p_odebrane_pilki);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20155, 'Liczba odebranych piłek ma być liczbą!');
    END;
    BEGIN
        v_liczba_strzalow := TO_NUMBER(p_liczba_strzalow);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20156, 'Liczba strzałów ma być liczbą!');
    END;
    BEGIN
        v_obronione_lub_zablokowane_strzaly := TO_NUMBER(p_obronione_lub_zablokowane_strzaly);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20157, 'Liczba obronionych lub zablokowanych strzałów ma być liczbą!');
    END;
    IF v_liczba_bramek < 0 THEN
   raise_application_error(-20011, 'Liczba strzelonych bramek ma być większa lub równa 0!');
   ELSIF v_liczba_bramek IS NOT NULL AND v_liczba_bramek != TRUNC(v_liczba_bramek) THEN
        raise_application_error(-20030, 'Liczba strzelonych bramek ma być liczbą całkowitą!');
    ELSIF v_liczba_bramek IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_liczba_bramek))) > 2 THEN
        raise_application_error(-20031, 'Liczba strzelonych bramek nie może mieć więcej niż 2 cyfry!');
    END IF;
    IF v_liczba_asyst < 0 THEN
   raise_application_error(-20012, 'Liczba zdobytych asyst ma być większa lub równa 0!');
   ELSIF v_liczba_asyst IS NOT NULL AND v_liczba_asyst != TRUNC(v_liczba_asyst) THEN
        raise_application_error(-20032, 'Liczba zdobytych asyst ma być liczbą całkowitą!');
    ELSIF v_liczba_asyst IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_liczba_asyst))) > 2 THEN
        raise_application_error(-20033, 'Liczba zdobytych asyst nie może mieć więcej niż 2 cyfry!');
    END IF;
    IF v_minuty_na_boisku < 0 THEN
   raise_application_error(-20013, 'Liczba minut na boisku ma być większa lub równa 0!');
   ELSIF v_minuty_na_boisku IS NOT NULL AND v_minuty_na_boisku != TRUNC(v_minuty_na_boisku) THEN
        raise_application_error(-20034, 'Liczba minut na boisku ma być liczbą całkowitą!');
    ELSIF v_minuty_na_boisku IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_minuty_na_boisku))) > 3 THEN
        raise_application_error(-20035, 'Liczba minut na boisku nie może mieć więcej niż 3 cyfry!');
    END IF;
    IF v_procent_celnych_podan < 0 OR v_procent_celnych_podan > 100 THEN
   raise_application_error(-20014, 'Procent celnych podań ma być z przedziału od 0 do 100!');
   ELSIF v_procent_celnych_podan IS NOT NULL AND v_procent_celnych_podan != TRUNC(v_procent_celnych_podan) THEN
        raise_application_error(-20036, 'Procent celnych podań ma być liczbą całkowitą!');
    ELSIF v_procent_celnych_podan IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_procent_celnych_podan))) > 3 THEN
        raise_application_error(-20037, 'Procent celnych podań nie może mieć więcej niż 3 cyfry!');
    END IF;
    IF v_podania < 0 THEN
   raise_application_error(-20015, 'Liczba podań ma być większa lub równa 0!');
   ELSIF v_podania IS NOT NULL AND v_podania != TRUNC(v_podania) THEN
        raise_application_error(-20038, 'Liczba podań ma być liczbą całkowitą!');
    ELSIF v_podania IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_podania))) > 4 THEN
        raise_application_error(-20039, 'Liczba podań nie może mieć więcej niż 4 cyfry!');
    END IF;
    IF v_odebrane_pilki < 0 THEN
   raise_application_error(-20016, 'Liczba odebranych piłek ma być większa lub równa 0!');
   ELSIF v_odebrane_pilki IS NOT NULL AND v_odebrane_pilki != TRUNC(v_odebrane_pilki) THEN
        raise_application_error(-20040, 'Liczba odebranych piłek ma być liczbą całkowitą!');
    ELSIF v_odebrane_pilki IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_odebrane_pilki))) > 3 THEN
        raise_application_error(-20041, 'Liczba odebranych piłek nie może mieć więcej niż 3 cyfry!');
    END IF;
    IF v_liczba_strzalow < 0 THEN
   raise_application_error(-20017, 'Liczba strzałów ma być większa lub równa 0!');
   ELSIF v_liczba_strzalow IS NOT NULL AND v_liczba_strzalow != TRUNC(v_liczba_strzalow) THEN
        raise_application_error(-20042, 'Liczba strzałów ma być liczbą całkowitą!');
    ELSIF v_liczba_strzalow IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_liczba_strzalow))) > 2 THEN
        raise_application_error(-20043, 'Liczba strzałów nie może mieć więcej niż 2 cyfry!');
    END IF;
    IF v_obronione_lub_zablokowane_strzaly < 0 THEN
   raise_application_error(-20018, 'Liczba obronionych lub zablokowanych strzałów ma być większa lub równa 0!');
   ELSIF v_obronione_lub_zablokowane_strzaly IS NOT NULL AND v_obronione_lub_zablokowane_strzaly != TRUNC(v_obronione_lub_zablokowane_strzaly) THEN
        raise_application_error(-20044, 'Liczba obronionych lub zablokowanych strzałów ma być liczbą całkowitą!');
    ELSIF v_obronione_lub_zablokowane_strzaly IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_obronione_lub_zablokowane_strzaly))) > 2 THEN
        raise_application_error(-20045, 'Liczba obronionych lub zablokowanych strzałów nie może mieć więcej niż 2 cyfry!');
    END IF;
    SELECT generacja_id_statystyk.NEXTVAL INTO v_id_statystyk FROM dual;
    -- Pobranie ID meczu na podstawie daty meczu
    BEGIN
        SELECT id_meczu, status_meczu
        INTO v_id_meczu, v_status_meczu
        FROM Mecze
        WHERE data_meczu = p_data_meczu;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            raise_application_error(-20099, 'Nie znaleziono meczu o podanej dacie!');
    END;

    IF v_status_meczu != 'Rozegrany' THEN
        RAISE_APPLICATION_ERROR(-20400, 'Statystyki można dodać tylko dla meczów, które zostały rozegrane!');
    END IF;

    -- Pobranie ID zawodnika na podstawie danych z tabeli Pracownicy
    SELECT z.id_zawodnika
    INTO v_id_zawodnika
    FROM Zawodnicy z
    INNER JOIN Pracownicy p ON z.id_zawodnika = p.id_pracownika
    WHERE p.imie = p_imie
      AND p.nazwisko = p_nazwisko
      AND p.data_urodzenia = p_data_urodzenia;

    SELECT COUNT(*)
    INTO v_count
    FROM Statystyki_zawodnikow
    WHERE id_meczu = v_id_meczu
      AND id_zawodnika = v_id_zawodnika;

    IF v_count > 0 THEN
        raise_application_error(-20019, 'Statystyki dla tego zawodnika w danym meczu już istnieją!');
    END IF;
    -- Wstawienie danych do tabeli Statystyki_zawodnikow
    INSERT INTO Statystyki_zawodnikow (
        id_statystyk,
        liczba_bramek,
        liczba_asyst,
        minuty_na_boisku,
        procent_celnych_podan,
        podania,
        odebrane_pilki,
        liczba_strzalow,
        obronione_lub_zablokowane_strzaly,
        id_meczu,
        id_zawodnika
    )
    VALUES (
        v_id_statystyk,
        v_liczba_bramek,
        v_liczba_asyst,
        v_minuty_na_boisku,
        v_procent_celnych_podan,
        v_podania,
        v_odebrane_pilki,
        v_liczba_strzalow,
        v_obronione_lub_zablokowane_strzaly,
        v_id_meczu,
        v_id_zawodnika
    );
END;
/
CREATE OR REPLACE PROCEDURE aktualizuj_dane_trenera (
    p_id_trenera       IN NUMBER,
    p_imie             IN VARCHAR2,
    p_nazwisko         IN VARCHAR2,
    p_data_urodzenia   IN DATE,
    p_obszar_trenerski IN VARCHAR2
)
IS
    v_count NUMBER;
BEGIN
    IF p_imie IS NULL THEN
   raise_application_error(-20001, 'Imię jest wymagane!');
   ELSIF LENGTH(p_imie) > 30 THEN
   raise_application_error(-20007, 'Imię nie może przekraczać 30 znaków!');
   ELSIF UPPER(SUBSTR(p_imie, 1, 1)) != SUBSTR(p_imie, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20200, 'Imię musi zaczynać się wielką literą!');
    END IF;
    IF p_nazwisko IS NULL THEN
   raise_application_error(-20002, 'Nazwisko jest wymagane!');
   ELSIF LENGTH(p_nazwisko) > 30 THEN
   raise_application_error(-20008, 'Nazwisko nie może przekraczać 30 znaków!');
   ELSIF UPPER(SUBSTR(p_nazwisko, 1, 1)) != SUBSTR(p_nazwisko, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20201, 'Nazwisko musi zaczynać się wielką literą!');
    END IF;
    IF p_data_urodzenia IS NULL THEN
   raise_application_error(-20003, 'Data urodzenia jest wymagana!');
    END IF;
    IF p_obszar_trenerski IS NULL THEN
   raise_application_error(-20004, 'Obszar trenerski jest wymagany!');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Pracownicy
    WHERE imie = p_imie
      AND nazwisko = p_nazwisko
      AND data_urodzenia = p_data_urodzenia
      AND id_pracownika != p_id_trenera;

    IF v_count > 0 THEN
        raise_application_error(-20005, 'Pracownik z takimi danymi weryfikacyjnymi już istnieje!');
    END IF;
    -- Aktualizacja danych w tabeli Pracownicy
    UPDATE Pracownicy
       SET imie = p_imie,
           nazwisko = p_nazwisko,
           data_urodzenia = p_data_urodzenia
     WHERE id_pracownika = p_id_trenera;

    -- Aktualizacja danych w tabeli Trenerzy
    UPDATE Trenerzy
       SET obszar_trenerski = p_obszar_trenerski
     WHERE id_trenera = p_id_trenera;
END aktualizuj_dane_trenera;
/
CREATE OR REPLACE PROCEDURE aktualizuj_dane_czlonka_zarzadu (
    p_id_czlonka_zarzadu IN NUMBER,
    p_imie               IN VARCHAR2,
    p_nazwisko           IN VARCHAR2,
    p_data_urodzenia     IN DATE,
    p_rola_zarzadcza     IN VARCHAR2
)
IS
    v_count NUMBER;
BEGIN
    IF p_imie IS NULL THEN
   raise_application_error(-20001, 'Imię jest wymagane!');
   ELSIF LENGTH(p_imie) > 30 THEN
   raise_application_error(-20007, 'Imię nie może przekraczać 30 znaków!');
   ELSIF UPPER(SUBSTR(p_imie, 1, 1)) != SUBSTR(p_imie, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20200, 'Imię musi zaczynać się wielką literą!');
    END IF;
    IF p_nazwisko IS NULL THEN
   raise_application_error(-20002, 'Nazwisko jest wymagane!');
   ELSIF LENGTH(p_nazwisko) > 30 THEN
   raise_application_error(-20008, 'Nazwisko nie może przekraczać 30 znaków!');
   ELSIF UPPER(SUBSTR(p_nazwisko, 1, 1)) != SUBSTR(p_nazwisko, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20201, 'Nazwisko musi zaczynać się wielką literą!');
    END IF;
    IF p_data_urodzenia IS NULL THEN
   raise_application_error(-20003, 'Data urodzenia jest wymagana!');
    END IF;
    IF p_rola_zarzadcza IS NULL THEN
   raise_application_error(-20004, 'Rola zarządcza jest wymagana!');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Pracownicy
    WHERE imie = p_imie
      AND nazwisko = p_nazwisko
      AND data_urodzenia = p_data_urodzenia
      AND id_pracownika != p_id_czlonka_zarzadu;

    IF v_count > 0 THEN
        raise_application_error(-20005, 'Pracownik z takimi danymi weryfikacyjnymi już istnieje!');
    END IF;
    -- Aktualizacja danych w tabeli Pracownicy
    UPDATE Pracownicy
       SET imie = p_imie,
           nazwisko = p_nazwisko,
           data_urodzenia = p_data_urodzenia
     WHERE id_pracownika = p_id_czlonka_zarzadu;

    -- Aktualizacja danych w tabeli Czlonkowie_zarzadu
    UPDATE Czlonkowie_zarzadu
       SET rola_zarzadcza = p_rola_zarzadcza
     WHERE id_czlonka_zarzadu = p_id_czlonka_zarzadu;
END aktualizuj_dane_czlonka_zarzadu;
/
CREATE OR REPLACE PROCEDURE EdytujBadanieZdrowotne (
    p_id_badania NUMBER,
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_urodzenia DATE,
    p_data_badania DATE,
    p_stan_zdrowia VARCHAR2,
    p_poziom_zmeczenia VARCHAR2,
    p_ryzyko_kontuzji VARCHAR2
) IS
    v_id_badanego NUMBER;
    v_count NUMBER;
BEGIN
    -- Znajdź ID badanego na podstawie podanych danych osobowych
    SELECT z.id_zawodnika
    INTO v_id_badanego
    FROM Pracownicy p
    JOIN Zawodnicy z ON p.id_pracownika = z.id_zawodnika
    WHERE p.imie = p_imie
      AND p.nazwisko = p_nazwisko
      AND p.data_urodzenia = p_data_urodzenia;

    IF p_imie IS NULL or p_nazwisko IS NULL or p_data_urodzenia IS NULL THEN
   raise_application_error(-20001, 'Dane badanego są wymagane!');
    END IF;
    IF p_data_badania IS NULL THEN
   raise_application_error(-20002, 'Data badania jest wymagana!');
    END IF;
    IF p_stan_zdrowia IS NULL THEN
   raise_application_error(-20003, 'Stan zdrowia jest wymagany!');
   ELSIF LENGTH(p_stan_zdrowia) > 150 THEN
   raise_application_error(-20007, 'Opis stanu zdrowia nie może przekraczać 150 znaków!');
    END IF;
    IF p_poziom_zmeczenia IS NULL THEN
   raise_application_error(-20004, 'Poziom zmęczenia jest wymagany!');
    END IF;
    IF p_ryzyko_kontuzji IS NULL THEN
   raise_application_error(-20005, 'Ryzyko kontuzji jest wymagane!');
    END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Badania_zdrowotne
    WHERE id_badanego = v_id_badanego
      AND data_badania = p_data_badania
      AND id_badania != p_id_badania;

    IF v_count > 0 THEN
        raise_application_error(-20006, 'Badanie dla tego zawodnika w tej dacie już istnieje!');
    END IF;
    -- Aktualizacja badania zdrowotnego, łącznie ze zmianą badanego
    UPDATE Badania_zdrowotne
    SET id_badanego = v_id_badanego,
        data_badania = p_data_badania,
        stan_zdrowia = p_stan_zdrowia,
        poziom_zmeczenia = p_poziom_zmeczenia,
        ryzyko_kontuzji = p_ryzyko_kontuzji
    WHERE id_badania = p_id_badania;
END;
/
CREATE OR REPLACE PROCEDURE AktualizujObiekt (
    p_id_obiektu NUMBER,
    p_nazwa VARCHAR2,
    p_typ VARCHAR2,
    p_pojemnosc VARCHAR2,
    p_lokalizacja VARCHAR2,
    p_ceny_biletow VARCHAR2
) IS
    v_count NUMBER;
    v_pojemnosc NUMBER;
    v_ceny_biletow NUMBER;
BEGIN
    IF p_nazwa IS NULL THEN
   raise_application_error(-20001, 'Nazwa obiektu jest wymagana!');
   ELSIF LENGTH(p_nazwa) > 60 THEN
   raise_application_error(-20009, 'Nazwa obiektu nie może przekraczać 60 znaków!');
   ELSIF UPPER(SUBSTR(p_nazwa, 1, 1)) != SUBSTR(p_nazwa, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20200, 'Nazwa obiektu musi zaczynać się wielką literą!');
    END IF;
    IF p_typ IS NULL THEN
   raise_application_error(-20002, 'Typ obiektu jest wymagany!');
    END IF;
    IF p_pojemnosc IS NULL THEN
   raise_application_error(-20003, 'Pojemność obiektu jest wymagana!');
    END IF;
    IF p_lokalizacja IS NULL THEN
   raise_application_error(-20004, 'Lokalizacja obiektu jest wymagana!');
   ELSIF LENGTH(p_lokalizacja) > 50 THEN
   raise_application_error(-20008, 'Lokalizacja nie może przekraczać 50 znaków!');
    END IF;
    BEGIN
        v_pojemnosc := TO_NUMBER(p_pojemnosc);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20150, 'Pojemność obiektu ma być liczbą!');
    END;
    BEGIN
        v_ceny_biletow := TO_NUMBER(p_ceny_biletow);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20151, 'Cena biletów ma być liczbą!');
    END;
    IF v_pojemnosc < 0 THEN
   raise_application_error(-20005, 'Pojemność obiektu ma być większa lub równa 0!');
   ELSIF v_pojemnosc IS NOT NULL AND v_pojemnosc != TRUNC(v_pojemnosc) THEN
        raise_application_error(-20015, 'Pojemność obiektu musi być liczbą całkowitą!');
    ELSIF v_pojemnosc IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_pojemnosc))) > 6 THEN
        raise_application_error(-20016, 'Pojemność obiektu nie może mieć więcej niż 6 cyfr!');
   
    END IF;
    IF v_ceny_biletow < 0 THEN
   raise_application_error(-20006, 'Ceny biletów mają być większe lub równe 0!');
   ELSIF v_ceny_biletow IS NOT NULL AND v_ceny_biletow != TRUNC(v_ceny_biletow) THEN
        raise_application_error(-20017, 'Ceny biletów muszą być liczbą całkowitą!');
    ELSIF v_ceny_biletow IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_ceny_biletow))) > 6 THEN
        raise_application_error(-20018, 'Ceny biletów nie mogą mieć więcej niż 6 cyfr!');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Obiekty_klubowe
    WHERE nazwa_obiektu = p_nazwa
      AND id_obiektu != p_id_obiektu;

    IF v_count > 0 THEN
        raise_application_error(-20007, 'Obiekt o podanej nazwie już istnieje!');
    END IF;
    -- Aktualizacja obiektu klubowego na podstawie id_obiektu
    UPDATE Obiekty_klubowe
    SET nazwa_obiektu = p_nazwa,
        typ_obiektu = p_typ,
        pojemnosc = v_pojemnosc,
        lokalizacja = p_lokalizacja,
        ceny_biletow = v_ceny_biletow
    WHERE id_obiektu = p_id_obiektu;
END;
/
CREATE OR REPLACE PROCEDURE AktualizujTransfer (
    p_id_transferu NUMBER,
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_urodzenia DATE,
    p_data_transferu DATE,
    p_typ_transferu VARCHAR2,
    p_oplata_transferowa VARCHAR2
) IS
    v_id_pracownika NUMBER;
    v_count NUMBER;
    v_oplata_transferowa NUMBER;
BEGIN
    IF p_imie IS NULL or p_nazwisko IS NULL or p_data_urodzenia IS NULL THEN
   raise_application_error(-20001, 'Dane transferowanego są wymagane!');
    END IF;
    IF p_data_transferu IS NULL THEN
   raise_application_error(-20002, 'Data transferu jest wymagana!');
    END IF;
    IF p_typ_transferu IS NULL THEN
   raise_application_error(-20003, 'Typ transferu jest wymagany!');
    END IF;
    IF p_oplata_transferowa IS NULL THEN
   raise_application_error(-20004, 'Opłata transferowa jest wymagana!');
    END IF;
    BEGIN
        v_oplata_transferowa := TO_NUMBER(p_oplata_transferowa);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20150, 'Opłata transferowa ma być liczbą!');
    END;
    IF v_oplata_transferowa < 0 THEN
   raise_application_error(-20005, 'Opłata transferowa ma być większa lub równa 0!');
   ELSIF v_oplata_transferowa IS NOT NULL AND v_oplata_transferowa != TRUNC(v_oplata_transferowa) THEN
        raise_application_error(-20015, 'Opłata transferowa musi być liczbą całkowitą!');
    ELSIF v_oplata_transferowa IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_oplata_transferowa))) > 11 THEN
        raise_application_error(-20016, 'Opłata transferowa nie może mieć więcej niż 11 cyfr!');
    END IF;
    -- Znajdź ID pracownika na podstawie danych osobowych
    SELECT id_pracownika
    INTO v_id_pracownika
    FROM Pracownicy
    WHERE imie = p_imie AND nazwisko = p_nazwisko AND data_urodzenia = p_data_urodzenia;

    SELECT COUNT(*)
    INTO v_count
    FROM Transfery
    WHERE id_transferowanego = v_id_pracownika
      AND data_transferu = p_data_transferu
      AND id_transferu != p_id_transferu;

    IF v_count > 0 THEN
        raise_application_error(-20006, 'Transfer dla tego zawodnika w tej dacie już istnieje!');
    END IF;
    -- Aktualizacja transferu w tabeli Transfery
    UPDATE Transfery
    SET id_transferowanego = v_id_pracownika,
        data_transferu = p_data_transferu,
        typ_transferu = p_typ_transferu,
        oplata_transferowa = v_oplata_transferowa
    WHERE id_transferu = p_id_transferu;
END;
/
CREATE OR REPLACE PROCEDURE UsunStatystykiZawodnikaZMeczu(
    p_id_statystyk NUMBER
) IS
BEGIN
DELETE FROM Statystyki_zawodnikow
WHERE id_statystyk=p_id_statystyk;
END;
/
CREATE OR REPLACE PROCEDURE AktualizujStatystykiZawodnika (
    p_id_statystyk NUMBER,
    p_data_meczu DATE,
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_urodzenia DATE,
    p_liczba_bramek VARCHAR2,
    p_liczba_asyst VARCHAR2,
    p_minuty_na_boisku VARCHAR2,
    p_procent_celnych_podan VARCHAR2,
    p_podania VARCHAR2,
    p_odebrane_pilki VARCHAR2,
    p_liczba_strzalow VARCHAR2,
    p_obronione_lub_zablokowane_strzaly VARCHAR2
) IS
    v_id_meczu NUMBER;
    v_id_zawodnika NUMBER;
    v_count NUMBER;
    v_liczba_bramek NUMBER;
    v_liczba_asyst NUMBER;
    v_minuty_na_boisku NUMBER;
    v_procent_celnych_podan NUMBER;
    v_podania NUMBER;
    v_odebrane_pilki NUMBER;
    v_liczba_strzalow NUMBER;
    v_obronione_lub_zablokowane_strzaly NUMBER;
    v_status_meczu VARCHAR2(30);
BEGIN
    IF p_imie IS NULL or p_nazwisko IS NULL or p_data_urodzenia IS NULL THEN
   raise_application_error(-20001, 'Dane uczestnika meczu są wymagane!');
    END IF;
    IF p_data_meczu IS NULL THEN
   raise_application_error(-20002, 'Data meczu jest wymagana!');
    END IF;
    IF p_liczba_bramek IS NULL THEN
   raise_application_error(-20003, 'Liczba strzelonych bramek jest wymagana!');
    END IF;
    IF p_liczba_asyst IS NULL THEN
   raise_application_error(-20004, 'Liczba zdobytych asyst jest wymagana!');
    END IF;
    IF p_minuty_na_boisku IS NULL THEN
   raise_application_error(-20005, 'Liczba minut na boisku jest wymagana!');
    END IF;
    IF p_procent_celnych_podan IS NULL THEN
   raise_application_error(-20006, 'Procent celnych podań jest wymagany!');
    END IF;
    IF p_podania IS NULL THEN
   raise_application_error(-20007, 'Liczba podań jest wymagana!');
    END IF;
    IF p_odebrane_pilki IS NULL THEN
   raise_application_error(-20008, 'Liczba odebranych piłek jest wymagana!');
    END IF;
    IF p_liczba_strzalow IS NULL THEN
   raise_application_error(-20009, 'Liczba strzałów jest wymagana!');
    END IF;
    IF p_obronione_lub_zablokowane_strzaly IS NULL THEN
   raise_application_error(-20010, 'Liczba obronionych lub zablokowanych strzałów jest wymagana!');
    END IF;
    BEGIN
        v_liczba_bramek := TO_NUMBER(p_liczba_bramek);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20150, 'Liczba bramek ma być liczbą!');
    END;
    BEGIN
        v_liczba_asyst := TO_NUMBER(p_liczba_asyst);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20151, 'Liczba asyst ma być liczbą!');
    END;
    BEGIN
        v_minuty_na_boisku := TO_NUMBER(p_minuty_na_boisku);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20152, 'Liczba minut na boisku ma być liczbą!');
    END;
    BEGIN
        v_procent_celnych_podan := TO_NUMBER(p_procent_celnych_podan);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20153, 'Procent celnych podań ma być liczbą!');
    END;
    BEGIN
        v_podania := TO_NUMBER(p_podania);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20154, 'Liczba podań ma być liczbą!');
    END;
    BEGIN
        v_odebrane_pilki := TO_NUMBER(p_odebrane_pilki);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20155, 'Liczba odebranych piłek ma być liczbą!');
    END;
    BEGIN
        v_liczba_strzalow := TO_NUMBER(p_liczba_strzalow);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20156, 'Liczba strzałów ma być liczbą!');
    END;
    BEGIN
        v_obronione_lub_zablokowane_strzaly := TO_NUMBER(p_obronione_lub_zablokowane_strzaly);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20157, 'Liczba obronionych lub zablokowanych strzałów ma być liczbą!');
    END;
    IF v_liczba_bramek < 0 THEN
   raise_application_error(-20011, 'Liczba strzelonych bramek ma być większa lub równa 0!');
   ELSIF v_liczba_bramek IS NOT NULL AND v_liczba_bramek != TRUNC(v_liczba_bramek) THEN
        raise_application_error(-20030, 'Liczba strzelonych bramek ma być liczbą całkowitą!');
    ELSIF v_liczba_bramek IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_liczba_bramek))) > 2 THEN
        raise_application_error(-20031, 'Liczba strzelonych bramek nie może mieć więcej niż 2 cyfry!');
    END IF;
    IF v_liczba_asyst < 0 THEN
   raise_application_error(-20012, 'Liczba zdobytych asyst ma być większa lub równa 0!');
   ELSIF v_liczba_asyst IS NOT NULL AND v_liczba_asyst != TRUNC(v_liczba_asyst) THEN
        raise_application_error(-20032, 'Liczba zdobytych asyst ma być liczbą całkowitą!');
    ELSIF v_liczba_asyst IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_liczba_asyst))) > 2 THEN
        raise_application_error(-20033, 'Liczba zdobytych asyst nie może mieć więcej niż 2 cyfry!');
    END IF;
    IF v_minuty_na_boisku < 0 THEN
   raise_application_error(-20013, 'Liczba minut na boisku ma być większa lub równa 0!');
   ELSIF v_minuty_na_boisku IS NOT NULL AND v_minuty_na_boisku != TRUNC(v_minuty_na_boisku) THEN
        raise_application_error(-20034, 'Liczba minut na boisku ma być liczbą całkowitą!');
    ELSIF v_minuty_na_boisku IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_minuty_na_boisku))) > 3 THEN
        raise_application_error(-20035, 'Liczba minut na boisku nie może mieć więcej niż 3 cyfry!');
    END IF;
    IF v_procent_celnych_podan < 0 OR v_procent_celnych_podan > 100 THEN
   raise_application_error(-20014, 'Procent celnych podań ma być z przedziału od 0 do 100!');
   ELSIF v_procent_celnych_podan IS NOT NULL AND v_procent_celnych_podan != TRUNC(v_procent_celnych_podan) THEN
        raise_application_error(-20036, 'Procent celnych podań ma być liczbą całkowitą!');
    ELSIF v_procent_celnych_podan IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_procent_celnych_podan))) > 3 THEN
        raise_application_error(-20037, 'Procent celnych podań nie może mieć więcej niż 3 cyfry!');
    END IF;
    IF v_podania < 0 THEN
   raise_application_error(-20015, 'Liczba podań ma być większa lub równa 0!');
   ELSIF v_podania IS NOT NULL AND v_podania != TRUNC(v_podania) THEN
        raise_application_error(-20038, 'Liczba podań ma być liczbą całkowitą!');
    ELSIF v_podania IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_podania))) > 4 THEN
        raise_application_error(-20039, 'Liczba podań nie może mieć więcej niż 4 cyfry!');
    END IF;
    IF v_odebrane_pilki < 0 THEN
   raise_application_error(-20016, 'Liczba odebranych piłek ma być większa lub równa 0!');
   ELSIF v_odebrane_pilki IS NOT NULL AND v_odebrane_pilki != TRUNC(v_odebrane_pilki) THEN
        raise_application_error(-20040, 'Liczba odebranych piłek ma być liczbą całkowitą!');
    ELSIF v_odebrane_pilki IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_odebrane_pilki))) > 3 THEN
        raise_application_error(-20041, 'Liczba odebranych piłek nie może mieć więcej niż 3 cyfry!');
    END IF;
    IF v_liczba_strzalow < 0 THEN
   raise_application_error(-20017, 'Liczba strzałów ma być większa lub równa 0!');
   ELSIF v_liczba_strzalow IS NOT NULL AND v_liczba_strzalow != TRUNC(v_liczba_strzalow) THEN
        raise_application_error(-20042, 'Liczba strzałów ma być liczbą całkowitą!');
    ELSIF v_liczba_strzalow IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_liczba_strzalow))) > 2 THEN
        raise_application_error(-20043, 'Liczba strzałów nie może mieć więcej niż 2 cyfry!');
    END IF;
    IF v_obronione_lub_zablokowane_strzaly < 0 THEN
   raise_application_error(-20018, 'Liczba obronionych lub zablokowanych strzałów ma być większa lub równa 0!');
   ELSIF v_obronione_lub_zablokowane_strzaly IS NOT NULL AND v_obronione_lub_zablokowane_strzaly != TRUNC(v_obronione_lub_zablokowane_strzaly) THEN
        raise_application_error(-20044, 'Liczba obronionych lub zablokowanych strzałów ma być liczbą całkowitą!');
    ELSIF v_obronione_lub_zablokowane_strzaly IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_obronione_lub_zablokowane_strzaly))) > 2 THEN
        raise_application_error(-20045, 'Liczba obronionych lub zablokowanych strzałów nie może mieć więcej niż 2 cyfry!');
    END IF;
    -- Pobranie ID meczu na podstawie daty meczu
    BEGIN
        SELECT id_meczu, status_meczu
        INTO v_id_meczu, v_status_meczu
        FROM Mecze
        WHERE data_meczu = p_data_meczu;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            raise_application_error(-20099, 'Nie znaleziono meczu o podanej dacie!');
    END;

    IF v_status_meczu != 'Rozegrany' THEN
        RAISE_APPLICATION_ERROR(-20400, 'Statystyki można dodać tylko dla meczów, które zostały rozegrane!');
    END IF;

    -- Pobranie ID zawodnika na podstawie danych z tabeli Pracownicy
    SELECT z.id_zawodnika
    INTO v_id_zawodnika
    FROM Zawodnicy z
    INNER JOIN Pracownicy p ON z.id_zawodnika = p.id_pracownika
    WHERE p.imie = p_imie
      AND p.nazwisko = p_nazwisko
      AND p.data_urodzenia = p_data_urodzenia;

    SELECT COUNT(*)
    INTO v_count
    FROM Statystyki_zawodnikow
    WHERE id_meczu = v_id_meczu
      AND id_zawodnika = v_id_zawodnika
      AND id_statystyk != p_id_statystyk;

    IF v_count > 0 THEN
        raise_application_error(-20019, 'Statystyki dla tego zawodnika w danym meczu już istnieją!');
    END IF;
    -- Aktualizacja istniejących statystyk
    UPDATE Statystyki_zawodnikow
    SET liczba_bramek = v_liczba_bramek,
        liczba_asyst = v_liczba_asyst,
        minuty_na_boisku = v_minuty_na_boisku,
        procent_celnych_podan = v_procent_celnych_podan,
        podania = v_podania,
        odebrane_pilki = v_odebrane_pilki,
        liczba_strzalow = v_liczba_strzalow,
        obronione_lub_zablokowane_strzaly = v_obronione_lub_zablokowane_strzaly,
        id_meczu = v_id_meczu,
        id_zawodnika = v_id_zawodnika
    WHERE id_statystyk = p_id_statystyk;
END;
/
CREATE OR REPLACE PROCEDURE AktualizujUczestnikaTreningu (
    p_id_uczestnictwa IN NUMBER,
    p_imie IN VARCHAR2,
    p_nazwisko IN VARCHAR2,
    p_data_urodzenia IN DATE,
    p_id_treningu      IN NUMBER,
    p_czy_indywidualny IN CHAR,
    p_grupa_treningowa IN VARCHAR2
) IS
    v_id_zawodnika NUMBER;
    v_count NUMBER;
BEGIN
    IF p_imie IS NULL or p_nazwisko IS NULL or p_data_urodzenia IS NULL THEN
   raise_application_error(-20001, 'Dane uczestnika treningu są wymagane!');
    END IF;
    IF p_id_treningu IS NULL THEN
   raise_application_error(-20002, 'Dane treningu są wymagane!');
    END IF;
    IF p_czy_indywidualny IS NULL THEN
   raise_application_error(-20003, 'Typ treningu jest wymagany!');
    END IF;
    IF p_grupa_treningowa IS NULL THEN
   raise_application_error(-20004, 'Grupa treningowa jest wymagana!');
   END IF;
    -- Pobranie ID zawodnika na podstawie danych osobowych
    SELECT z.id_zawodnika
    INTO v_id_zawodnika
    FROM Zawodnicy z
    INNER JOIN Pracownicy p ON z.id_zawodnika = p.id_pracownika
    WHERE p.imie = p_imie
      AND p.nazwisko = p_nazwisko
      AND p.data_urodzenia = p_data_urodzenia;

    SELECT COUNT(*)
    INTO v_count
    FROM Uczestnicy_treningow
    WHERE id_treningu = p_id_treningu
      AND id_zawodnika = v_id_zawodnika
      AND id_uczestnictwa != p_id_uczestnictwa;

    IF v_count > 0 THEN
        raise_application_error(-20005, 'Uczestnik jest już przypisany do tego treningu!');
    END IF;
    -- Aktualizacja istniejącego uczestnictwa w treningu
    UPDATE Uczestnicy_treningow
    SET id_zawodnika = v_id_zawodnika,
        id_treningu = p_id_treningu,
        czy_indywidualny = p_czy_indywidualny,
        grupa_treningowa = p_grupa_treningowa
    WHERE id_uczestnictwa = p_id_uczestnictwa;
END;
/
CREATE OR REPLACE PROCEDURE AktualizujMecz (
    p_id_meczu IN NUMBER,
    p_przeciwnik IN VARCHAR2,
    p_data_meczu IN DATE,
    p_typ_rozgrywek IN VARCHAR2,
    p_status_meczu IN VARCHAR2,
    p_typ_meczu IN CHAR,
    p_gole_strzelone IN VARCHAR2,
    p_gole_stracone IN VARCHAR2,
    p_nazwa_obiektu_meczowego IN VARCHAR2 DEFAULT NULL,
    p_stadion_wyjazdowy IN VARCHAR2 DEFAULT NULL
) IS
    v_typ_meczu CHAR;
    v_id_obiektu_meczowego NUMBER;
    v_count NUMBER;
    v_gole_strzelone NUMBER;
    v_gole_stracone NUMBER;
BEGIN
    IF p_przeciwnik IS NULL THEN
   raise_application_error(-20001, 'Przeciwnik jest wymagany!');
   ELSIF LENGTH(p_przeciwnik) > 50 THEN
   raise_application_error(-20011, 'Przeciwnik nie może mieć dłuższej nazwy niż 50 znaków!');
   ELSIF UPPER(SUBSTR(p_przeciwnik, 1, 1)) != SUBSTR(p_przeciwnik, 1, 1) THEN
        RAISE_APPLICATION_ERROR(-20200, 'Przeciwnik musi zaczynać się wielką literą!');
    END IF;
    IF p_data_meczu IS NULL THEN
   raise_application_error(-20002, 'Data meczu jest wymagana!');
    END IF;
    IF p_typ_rozgrywek IS NULL THEN
   raise_application_error(-20003, 'Typ rozgrywek jest wymagany!');
    END IF;
    IF p_status_meczu IS NULL THEN
   raise_application_error(-20004, 'Status meczu jest wymagany!');
    END IF;
    IF p_typ_meczu IS NULL THEN
   raise_application_error(-20005, 'Typ meczu jest wymagany!');
    END IF;
    IF p_nazwa_obiektu_meczowego IS NULL AND p_typ_meczu='D' THEN
   raise_application_error(-20006, 'Obiekt meczowy dla meczu domowego jest wymagany!');
    END IF;
    IF p_stadion_wyjazdowy IS NULL AND p_typ_meczu='W' THEN
   raise_application_error(-20007, 'Obiekt meczowy dla meczu wyjazdowego jest wymagany!');
   ELSIF LENGTH(p_stadion_wyjazdowy) > 60 AND p_typ_meczu='W' THEN
   raise_application_error(-20012, 'Stadion wyjazdowy nie może mieć dłuższej nazwy niż 60 znaków!');
   ELSIF UPPER(SUBSTR(p_stadion_wyjazdowy, 1, 1)) != SUBSTR(p_stadion_wyjazdowy, 1, 1) AND p_typ_meczu='W' THEN
        RAISE_APPLICATION_ERROR(-20201, 'Nazwa stadionu wyjazdowego musi zaczynać się wielką literą!');
    END IF;
    BEGIN
        v_gole_strzelone := TO_NUMBER(p_gole_strzelone);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20150, 'Gole strzelone mają być liczbą!');
    END;
    BEGIN
        v_gole_stracone := TO_NUMBER(p_gole_stracone);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            raise_application_error(-20151, 'Gole stracone mają być liczbą!');
    END;
    IF p_status_meczu != 'Rozegrany' and (v_gole_strzelone IS NOT NULL OR v_gole_stracone IS NOT NULL) THEN
            RAISE_APPLICATION_ERROR(-20020, 'Jeśli mecz nie jest rozegrany, gole strzelone i stracone muszą być puste!');
    END IF;
    IF v_gole_strzelone < 0 THEN
   raise_application_error(-20008, 'Liczba goli strzelonych ma być większa lub równa 0!');
   ELSIF v_gole_strzelone IS NOT NULL AND v_gole_strzelone != TRUNC(v_gole_strzelone) THEN
        raise_application_error(-20015, 'Liczba goli strzelonych musi być liczbą całkowitą!');
    ELSIF v_gole_strzelone IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_gole_strzelone))) > 3 THEN
        raise_application_error(-20016, 'Liczba goli strzelonych nie może mieć więcej niż 3 cyfry!');
    END IF;
    IF v_gole_stracone < 0 THEN
   raise_application_error(-20009, 'Liczba goli straconych ma być większa lub równa 0!');
   ELSIF v_gole_stracone IS NOT NULL AND v_gole_stracone != TRUNC(v_gole_stracone) THEN
        raise_application_error(-20017, 'Liczba goli straconych musi być liczbą całkowitą!');
    ELSIF v_gole_stracone IS NOT NULL AND LENGTH(TO_CHAR(TRUNC(v_gole_stracone))) > 3 THEN
        raise_application_error(-20018, 'Liczba goli straconych nie może mieć więcej niż 3 cyfry!');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Mecze
    WHERE data_meczu = p_data_meczu
      AND id_meczu != p_id_meczu;

    IF v_count > 0 THEN
        raise_application_error(-20010, 'Podana data meczu jest już zajęta!');
    END IF;
    -- Pobranie obecnego typu meczu
    SELECT typ_meczu
    INTO v_typ_meczu
    FROM Mecze
    WHERE id_meczu = p_id_meczu;

    -- Pobranie ID obiektu na podstawie nazwy (tylko dla meczu domowego)
    IF p_typ_meczu = 'D' THEN
        SELECT id_obiektu
        INTO v_id_obiektu_meczowego
        FROM Obiekty_klubowe
        WHERE nazwa_obiektu = p_nazwa_obiektu_meczowego;
    END IF;

    -- Aktualizacja głównych danych meczu
    UPDATE Mecze
    SET data_meczu = p_data_meczu,
        przeciwnik = p_przeciwnik,
        typ_rozgrywek = p_typ_rozgrywek,
        status_meczu = p_status_meczu,
        gole_strzelone = v_gole_strzelone,
        gole_stracone = v_gole_stracone,
        typ_meczu = p_typ_meczu
    WHERE id_meczu = p_id_meczu;

    -- Jeśli typ meczu się zmienił, dostosuj tabele szczegółowe
    IF v_typ_meczu != p_typ_meczu THEN
        -- Usunięcie powiązań ze starą tabelą
        IF v_typ_meczu = 'D' THEN
            DELETE FROM Mecze_domowe WHERE id_meczu_domowego = p_id_meczu;
        ELSIF v_typ_meczu = 'W' THEN
            DELETE FROM Mecze_wyjazdowe WHERE id_meczu_wyjazdowego = p_id_meczu;
        END IF;

        -- Dodanie powiązań do nowej tabeli
        IF p_typ_meczu = 'D' THEN
            INSERT INTO Mecze_domowe (id_meczu_domowego, id_obiektu_meczowego)
            VALUES (p_id_meczu, v_id_obiektu_meczowego);
        ELSIF p_typ_meczu = 'W' THEN
            INSERT INTO Mecze_wyjazdowe (id_meczu_wyjazdowego, stadion_wyjazdowy)
            VALUES (p_id_meczu, p_stadion_wyjazdowy);
        END IF;
    ELSE
        -- Jeśli typ się nie zmienił, zaktualizuj istniejącą tabelę
        IF p_typ_meczu = 'D' THEN
            UPDATE Mecze_domowe
            SET id_obiektu_meczowego = v_id_obiektu_meczowego
            WHERE id_meczu_domowego = p_id_meczu;
        ELSIF p_typ_meczu = 'W' THEN
            UPDATE Mecze_wyjazdowe
            SET stadion_wyjazdowy = p_stadion_wyjazdowy
            WHERE id_meczu_wyjazdowego = p_id_meczu;
        END IF;
    END IF;
END;
/
CREATE OR REPLACE PROCEDURE AktualizujTrening (
    p_id_treningu          NUMBER,
    p_imie_trenera         VARCHAR2,
    p_nazwisko_trenera     VARCHAR2,
    p_data_urodzenia_trenera DATE,
    p_data_treningu        DATE,
    p_godzina_rozpoczecia VARCHAR2,
    p_godzina_zakonczenia VARCHAR2,
    p_nazwa_obiektu        VARCHAR2
) IS
    v_id_trener NUMBER;
    v_id_obiektu NUMBER;
    v_count NUMBER;
    v_godzina_rozpoczecia TIMESTAMP;
    v_godzina_zakonczenia TIMESTAMP;
BEGIN
    IF p_imie_trenera IS NULL or p_nazwisko_trenera IS NULL or p_data_urodzenia_trenera IS NULL THEN
   raise_application_error(-20001, 'Dane trenera prowadzącego są wymagane!');
    END IF;
    IF p_data_treningu IS NULL THEN
   raise_application_error(-20002, 'Data treningu jest wymagana!');
    END IF;
    IF p_nazwa_obiektu IS NULL THEN
   raise_application_error(-20003, 'Obiekt, na którym odbywa się trening jest wymagany!');
    END IF;
    IF p_godzina_rozpoczecia IS NULL THEN
   raise_application_error(-20050, 'Godzina rozpoczęcia treningu jest wymagana!');
   END IF;
   IF p_godzina_zakonczenia IS NULL THEN
   raise_application_error(-20051, 'Godzina zakończenia treningu jest wymagana!');
   END IF;
   v_godzina_rozpoczecia := TO_TIMESTAMP(p_godzina_rozpoczecia, 'MM/DD/YYYY HH24:MI');
   v_godzina_zakonczenia := TO_TIMESTAMP(p_godzina_zakonczenia, 'MM/DD/YYYY HH24:MI');
   IF TRUNC(v_godzina_rozpoczecia)!=p_data_treningu or TRUNC(v_godzina_zakonczenia)!=p_data_treningu THEN
   raise_application_error(-20053, 'Godziny trwania treningu mają być tego samego dnia co data treningu!');
    END IF;
   IF v_godzina_zakonczenia<v_godzina_rozpoczecia THEN
   raise_application_error(-20052, 'Godzina zakończenia treningu ma być późniejsza niż godzina rozpoczęcia treningu!');
   END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Treningi
    WHERE data_treningu = p_data_treningu and godzina_rozpoczecia=v_godzina_rozpoczecia and godzina_zakonczenia=v_godzina_zakonczenia AND id_treningu != p_id_treningu;

    IF v_count > 0 THEN
        raise_application_error(-20004, 'Podane data oraz godziny treningu są już zajęte!');
    END IF;
    -- Pobranie ID trenera na podstawie danych personalnych
    SELECT id_pracownika
    INTO v_id_trener
    FROM Pracownicy
    JOIN Trenerzy ON Pracownicy.id_pracownika = Trenerzy.id_trenera
    WHERE imie = p_imie_trenera 
      AND nazwisko = p_nazwisko_trenera 
      AND data_urodzenia = p_data_urodzenia_trenera;

    -- Pobranie ID obiektu na podstawie nazwy obiektu
    SELECT id_obiektu
    INTO v_id_obiektu
    FROM Obiekty_klubowe
    WHERE nazwa_obiektu = p_nazwa_obiektu;

    -- Aktualizacja danych treningu
    UPDATE Treningi
    SET id_trenera_prowadzacego = v_id_trener,
        data_treningu = p_data_treningu,
        godzina_rozpoczecia = v_godzina_rozpoczecia,
        godzina_zakonczenia = v_godzina_zakonczenia,
        id_obiektu_treningowego = v_id_obiektu
    WHERE id_treningu = p_id_treningu;
END;
/