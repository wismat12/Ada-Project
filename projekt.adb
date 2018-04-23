-- Projekt.adb

-- Spis tresci
-- 1. Includy (wiadomo)
-- 2. Nieprzyporzadkowane smieci lub zmienne globalne
-- 3. Deklaracje taskow
---- 3.1 CLI
---- 3.2 Klient
---- 3.3 Obsluga
---- 3.4 Kontroler
---- 3.5 Spawner obslugi
---- 3.6 Spawner klientow
-- 4. Definicje taskow
---- 4.1 CLI
---- 4.2 Klient
---- 4.3 Obsluga
---- 4.4 Kontroler
---- 4.5 Spawner obslugi
---- 4.6 Spawner klientow
-- 5. Procedura glowna


--#################################
-- 1. Includy

with Ada.Text_IO;
use Ada.Text_IO;
with Ada.Float_Text_IO;
use Ada.Float_Text_IO;

with Ada.Numerics.Float_Random;
use Ada.Numerics.Float_Random;

with Ada.Strings;
use Ada.Strings;
with Ada.Strings.Fixed;
use Ada.Strings.Fixed;

with Ada.Numerics.Generic_Elementary_Functions;

with Ada.Characters.Latin_1; -- obsluga ESC
with GNAT.OS_Lib; -- wyjscie z programu

with FIFO; -- bo kontroler lubi kolejki

procedure Projekt is

--#################################
-- 2. Nieprzyporzadkowane smieci lub zmienne globalne

  package Int_FIFO is new FIFO (Integer); -- kolejka do kontrolera
  use Int_FIFO;

  -- Czas symulacji
  Godzina : Integer;
  Minuta : Integer;
  Sekunda : Integer;

  -- Skalowanie czasu
  Skale : array(1..10) of Float := (0.5, 1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0, 128.0, 256.0);
  WybranaSkala : Integer := 2;
  CzasKroku : Duration := 1.0; -- Sekunda/Skala



  type Rodzaj_klienta is (Detaliczny, Firmowy, Inwestor, Hipoteka);

  type Pozycja is record
    Nr_porzadkowy: Integer;
    X: Integer;
    Y: Integer;
    Wolna: Boolean;
  end record;

  PoczekalniaPelna : Pozycja := (0,0,0,false); -- with Atomic;
  Poczekalnia1     : Pozycja := (1,8,36,true); -- with Atomic;
  Poczekalnia2     : Pozycja := (2,17,36,true);-- with Atomic;
  Poczekalnia3     : Pozycja := (3,26,36,true);-- with Atomic;
  Poczekalnia4     : Pozycja := (4,35,36,true);-- with Atomic;
  Poczekalnia5     : Pozycja := (5,44,36,true);-- with Atomic;
  Poczekalnia6     : Pozycja := (6,53,36,true);-- with Atomic;
  Terminal         : Pozycja := (1,79,36,true);-- with Atomic;
  Wejscie          : Pozycja := (1,99,38,true);-- with Atomic;
  Wyjscie          : Pozycja := (1,99,20,true);-- with Atomic;
  Stanowisko1      : Pozycja := (1,12,16,true);-- with Atomic;
  Stanowisko2      : Pozycja := (2,27,16,true);-- with Atomic;
  Stanowisko3      : Pozycja := (3,42,16,true);-- with Atomic;
  Stanowisko4      : Pozycja := (4,58,16,true);-- with Atomic;
  Stanowisko5      : Pozycja := (5,73,16,true);-- with Atomic;
  Stanowisko6      : Pozycja := (6,88,16,true);-- with Atomic;
  Pokoj_Obslugi1   : Pozycja := (1,25,12,true);-- with Atomic;
  Pokoj_Obslugi2   : Pozycja := (2,75,12,true);-- with Atomic;

  LOG_Zdarzenie    : Pozycja := (1,17,2,true); -- with Atomic; - wasy na samej gorze
  LOG_ST1          : Pozycja := (1,7,3,true);  -- with Atomic;
  LOG_ST2          : Pozycja := (2,7,4,true);  -- with Atomic;
  LOG_ST3          : Pozycja := (3,7,5,true);  -- with Atomic;
  LOG_ST4          : Pozycja := (4,7,6,true);  -- with Atomic;
  LOG_ST5          : Pozycja := (5,7,7,true);  -- with Atomic;
  LOG_ST6          : Pozycja := (6,7,8,true);  -- with Atomic;
  LOG_STString1    : Pozycja := (1,16,3,true); -- with Atomic;
  LOG_STString2    : Pozycja := (2,16,4,true); -- with Atomic;
  LOG_STString3    : Pozycja := (3,16,5,true); -- with Atomic;
  LOG_STString4    : Pozycja := (4,16,6,true); -- with Atomic;
  LOG_STString5    : Pozycja := (5,16,7,true); -- with Atomic;
  LOG_STString6    : Pozycja := (6,16,8,true); -- with Atomic;


  type TabPozycje is array(1..6) of Pozycja;


  TabStanowiska: TabPozycje:= (Stanowisko1, Stanowisko2, Stanowisko3, Stanowisko4, Stanowisko5, Stanowisko6);
  TabPoczekalnie: TabPozycje:= (Poczekalnia1, Poczekalnia2, Poczekalnia3, Poczekalnia4, Poczekalnia5, Poczekalnia6);

  LICZBA_KLIENTOW_W_BANKU : Integer := 0;    --globalna zmienna,licznik klientow, nie moze przekorczyc 13

  function ChcePozycjeLOG(chce: String; St: in Pozycja) return Pozycja is
  begin
    if chce = "LOG_ST" then
      if St.Nr_porzadkowy = 1 then return LOG_ST1;   --POZWALA OGARNAC gdzie pisc komunikaty w zal od taska
      elsif St.Nr_porzadkowy = 2 then return LOG_ST2;
      elsif St.Nr_porzadkowy = 3 then return LOG_ST3;
      elsif St.Nr_porzadkowy = 4 then return LOG_ST4;
      elsif St.Nr_porzadkowy = 5 then return LOG_ST5;
      elsif St.Nr_porzadkowy = 6 then return LOG_ST6;
      end if;
    elsif chce = "LOG_STString" then
      if St.Nr_porzadkowy = 1  then return LOG_STString1;
      elsif St.Nr_porzadkowy = 2 then return LOG_STString2;
      elsif St.Nr_porzadkowy = 3 then return LOG_STString3;
      elsif St.Nr_porzadkowy = 4 then return LOG_STString4;
      elsif St.Nr_porzadkowy = 5 then return LOG_STString5;
      elsif St.Nr_porzadkowy = 6 then return LOG_STString6;
      end if;
    else
      return LOG_Zdarzenie;
    end if;
  end ChcePozycjeLOG;

--#################################
-- 3. Deklaracje taskow
---- 3.1 CLI
  task CLI is
    entry Start;
    entry Print_Klient(x, y: Integer); -- wypisuje w (x,y) znak "o"
    entry Print_Obsluga(x, y, nr_pracownika: Integer); -- wypisuje w (x,y) nr_pracownika
    entry Print_LOG(S: String; Poz: Pozycja);
    entry CzyscZnak(x, y: Integer); -- wstawia pusta spacje w (x,y)
    entry wypiszCzas(godz, min: Integer);
  end CLI;
---- 3.2 Klient
  task type Klient is
    entry Start(taskNr: Integer);
    entry IdzTerminal;
    entry IdzStanowisko(st: Pozycja; nr: Integer);
  end Klient;
---- 3.3 Obsluga
  task type Obsluga is
    entry Start;
    entry IdzStanowisko(Sta: Pozycja; numer : Integer);
    entry IdzWyjscie;
    entry Sprawa(Czas_sprawy: Integer; nr_klienta: Integer; rodzaj: Rodzaj_klienta);
    entry JakieStan(odp: out Pozycja);
  end Obsluga;
---- 3.4 Kontroler
  task Kontroler is
    entry Start;
    entry PobierzBilet(nr: out Integer);
    entry ZglosOczekiwanieKlienta(nrKlienta: Integer);
    entry ZglosWolneStanowisko(nr_pracownika: Integer);
    entry CzyscKolejke;
  end Kontroler;

---- 3.5 Generator pracownikow obslugi
  task SpawnerObslugi is
    entry Start;
  end SpawnerObslugi;

---- 3.6 Generator klientow
  task SpawnerKlientow is
    entry Start;
  end SpawnerKlientow;


---- 3.7 Pomocnicze tablice
  type TabObsluga is array(1..6) of Obsluga;
  type Tabklienci is array(1..15) of Klient;

  TabKlientow: TabKlienci;
  TabPracownicy: TabObsluga;

--#################################
-- 4. Definicje taskow
---- 4.1 CLI
  task body CLI is

    type Atrybuty is (Czysty, Jasny, Podkreslony, Negatyw, Migajacy, Szary);

    procedure Pisz_XY(X,Y: Positive; S: String; Atryb : Atrybuty := Czysty);
    procedure Czysc;
    procedure Tlo;

    function Atryb_Fun(Atryb : Atrybuty) return String is
    (case Atryb is
     when Jasny => "1m", when Podkreslony => "4m", when Negatyw => "7m",
     when Migajacy => "5m", when Szary => "2m", when Czysty => "0m");

    function Esc_XY(X,Y : Positive) return String is
    ( (ASCII.ESC & "[" & Trim(Y'Img,Both) & ";" & Trim(X'Img,Both) & "H") );

    procedure Pisz_XY(X,Y: Positive; S: String; Atryb : Atrybuty := Czysty) is
      Przed : String := ASCII.ESC & "[" & Atryb_Fun(Atryb);
    begin
      Put( Esc_XY(X,Y) & S);
    end Pisz_XY;

    procedure Czysc is
    begin
      Put(ASCII.ESC & "[2J");
    end Czysc;

    procedure Tlo is
    begin
      Czysc; -- x   0                        25                       50                        75                     100
      Pisz_XY(1,1,  "||--[       ]------------------------------------LOG----------------------------------------------||");
      Pisz_XY(1,2,  "||------------{                                                                      }------------||");
      Pisz_XY(1,3,  "|ST1=>                                                                                             |");
      Pisz_XY(1,4,  "|ST2=>                                                                                             |");
      Pisz_XY(1,5,  "|ST3=>                                                                                             |");
      Pisz_XY(1,6,  "|ST4=>                                                                                             |");
      Pisz_XY(1,7,  "|ST5=>                                                                                             |");
      Pisz_XY(1,8,  "|ST6=>                                                                                             |");
      Pisz_XY(1,9,  "||------------------------------------------POKOJ OBSLUGI-----------------------------------------||");
      Pisz_XY(1,10, "||                                                                                                ||");
      Pisz_XY(1,11, "||                                                                                                ||");
      Pisz_XY(1,12, "||------------------         ------------------------------------------         ------------------||"); -- x,12
      Pisz_XY(1,13, "||                                                                                                ||");
      Pisz_XY(1,14, "||                                                                                                ||");
      Pisz_XY(1,15, "||      |     |        |     |        |     |         |     |        |     |        |     |       ||"); -- x,15
      Pisz_XY(1,16, "||--------st1------------st2------------st3-------------st4------------st5------------st6---------||");
      Pisz_XY(1,17, "||      |     |        |     |        |     |         |     |        |     |        |     |       ||"); -- x,17
      Pisz_XY(1,18, "||                                                                                                ||");
      Pisz_XY(1,19, "||                                                                                                ||");
      Pisz_XY(1,20, "||                                                                                                 /"); -- 100,20
      Pisz_XY(1,21, "||                                                                                                ||");
      Pisz_XY(1,22, "||                                                                                                ||");
      Pisz_XY(1,23, "||                                                                                                ||");
      Pisz_XY(1,24, "||                                                                                                ||");
      Pisz_XY(1,25, "||                                                                                                ||");
      Pisz_XY(1,26, "||                                                                                                ||");
      Pisz_XY(1,27, "||                                                                                                ||");
      Pisz_XY(1,28, "||                                                                                                ||");
      Pisz_XY(1,29, "||                                                                                                ||");
      Pisz_XY(1,30, "||                                                                                                ||");
      Pisz_XY(1,31, "||                                                                                                ||");
      Pisz_XY(1,32, "||                                                                                                ||");
      Pisz_XY(1,33, "||                                                                                                ||");
      Pisz_XY(1,34, "||                                                                                                ||");
      Pisz_XY(1,35, "||                                                                                                ||");
      Pisz_XY(1,36, "||   |_ _|    |_ _|    |_ _|    |_ _|    |_ _|    |_ _|                     |[^]|                 ||"); -- x,36
      Pisz_XY(1,37, "||                                                                                                ||");
      Pisz_XY(1,38, "||                                                                                                 /"); -- 100,38
      Pisz_XY(1,39, "||                                                                                                ||");
      Pisz_XY(1,40, "||------------------------------------------------------------------------------------------------||");
    end Tlo;

  begin
    accept Start;
    Tlo;
    loop
      select
        accept Print_Klient(x,y: Integer) do
          Pisz_XY(x,y,"o");
        end Print_Klient;
      or
        accept Print_Obsluga(x,y,nr_pracownika: Integer) do
          Pisz_XY(x,y,nr_pracownika'Img, Migajacy);
        end Print_Obsluga;
      or
        accept Print_LOG(S: String; Poz: Pozycja) do
          Pisz_XY(Poz.X,Poz.Y,"                                                               ");
          Pisz_XY(Poz.X,Poz.Y,S);
        end Print_LOG;
      or
        accept CzyscZnak(x, y: Integer) do
          Pisz_XY(x,y," ");
        end CzyscZnak;
      or
        accept wypiszCzas(godz, min: Integer) do
          Pisz_XY(6,1, "   ");
          Pisz_XY(6,1, godz'Img);
          Pisz_XY(9,1, ":");
          Pisz_XY(10,1,"   ");
          Pisz_XY(10,1,min'Img);
        end wypiszCzas;
      end select;
    end loop;
  end CLI;


---- 4.2 Klient
  task body Klient is
    PosX: Integer;
    PosY: Integer;
    Cel: Pozycja;
    Rodzaj: Rodzaj_klienta;
    CzasTrwaniaSprawy: Integer; --Do ogarniecia czasu z pracownikiem

    Nr_taska: Integer;
    Nr_klienta: Integer;
    Nr_pracownika: Integer; -- pracownik do ktorego zostal przypisany ten klient
    Gen: Generator;
    Numerek_losowy: Integer;

  begin
    accept Start(taskNr: Integer) do
      Nr_taska := taskNr;
    end Start;

    Reset(Gen);
    loop

      CzasTrwaniaSprawy := 300 + Integer(600.0 * (Random(Gen))); -- od 5 do 15 minut
      accept IdzTerminal;

      LICZBA_KLIENTOW_W_BANKU := LICZBA_KLIENTOW_W_BANKU + 1;
      CLI.Print_LOG("Obecnie w banku jest" & LICZBA_KLIENTOW_W_BANKU'Img & " klientow" , LOG_Zdarzenie);

      PosX := Wejscie.X;
      PosY := Wejscie.Y;

      -- 10% hipotecznych, 20% inwestorów, 20% firmowych, 50% detalicznych
      Numerek_losowy := Integer(100.0*Random(Gen));
      if Numerek_losowy <= 10 then
        Rodzaj := Hipoteka;
      elsif Numerek_losowy <= 30 then
        Rodzaj := Inwestor;
      elsif Numerek_losowy <= 50 then
        Rodzaj := Firmowy;
      else
        Rodzaj := Detaliczny;
      end if;

      -- Pielgrzymka do terminala
      Terminal.Wolna := False;
      while (PosX /= Terminal.X) loop
        CLI.CzyscZnak(PosX,PosY);
        PosX := PosX - 1;
        CLI.Print_Klient(PosX,PosY);
        delay CzasKroku;
      end loop;

      CLI.CzyscZnak(PosX,PosY);
      PosY := PosY - 1;
      CLI.Print_Klient(PosX,PosY);
      delay CzasKroku*3;

      -- Jest pod terminalem, pobiera bilet
      Kontroler.PobierzBilet(Nr_klienta);

      loop--szuka wolnej poczekalni
        Numerek_losowy :=1 + Integer(5.0 * (Random(Gen)));
        if TabPoczekalnie(Numerek_losowy).Wolna then
          TabPoczekalnie(Numerek_losowy).Wolna := false;
          Cel := TabPoczekalnie(Numerek_losowy);
          exit;
        end if;
        delay 15*CzasKroku;
      end loop;

      Terminal.Wolna := True;

      delay CzasKroku;
      CLI.CzyscZnak(PosX,PosY);
      PosY := PosY + 1;
      CLI.Print_Klient(PosX,PosY);
      delay CzasKroku;

      while (PosX /= Cel.X) loop
        CLI.CzyscZnak(PosX,PosY);
        PosX := PosX - 1;
        CLI.Print_Klient(PosX,PosY);
        delay CzasKroku;
      end loop;

      while (PosY /= Cel.Y) loop
        CLI.CzyscZnak(PosX,PosY);
        PosY := PosY - 1;
        CLI.Print_Klient(PosX,PosY);
        delay CzasKroku;
      end loop;

      --Jest w poczekalni
      Kontroler.ZglosOczekiwanieKlienta(Nr_taska);


      -- sygnal od Kontrolera
      accept IdzStanowisko(st: in Pozycja; nr: in Integer) do
        Cel := st;
        Nr_pracownika := nr;
      end IdzStanowisko;

      TabPoczekalnie(Numerek_losowy).Wolna := true;

      delay CzasKroku*5;
      -- Pielgrzymka do stanowiska

      while (PosY /= Cel.Y + 2) loop
        CLI.CzyscZnak(PosX,PosY);
        PosY := PosY - 1;
        CLI.Print_Klient(PosX,PosY);
        delay CzasKroku;
      end loop;

      if PosX > Cel.X then
        while (PosX /= Cel.X -1) loop
          CLI.CzyscZnak(PosX,PosY);
          PosX := PosX - 1;
          CLI.Print_Klient(PosX,PosY);
          delay CzasKroku;
        end loop;
      else -- PosX <= Stanowisko.X
        while (PosX /= Cel.X + 1) loop
          CLI.CzyscZnak(PosX,PosY);
          PosX := PosX + 1;
          CLI.Print_Klient(PosX,PosY);
          delay CzasKroku;
        end loop;
      end if;

      CLI.CzyscZnak(PosX,PosY);
      PosY := PosY - 1;
      CLI.Print_Klient(PosX,PosY); -- tutaj sobie wchodzi do stanowiska, o jeden w gore
      --powinien byc w stanowisku :)

      -- sygnal do Pracownika
      TabPracownicy(Nr_pracownika).Sprawa(CzasTrwaniaSprawy, Nr_klienta, Rodzaj);

      while (PosY /= Wyjscie.Y) loop
        CLI.Print_Klient(PosX,PosY);
        PosY := PosY + 1;
        delay CzasKroku;
        CLI.CzyscZnak(PosX,PosY-1);
      end loop;
      while (PosX /= Wyjscie.X ) loop
        CLI.Print_Klient(PosX,PosY);
        PosX := PosX + 1;
        delay CzasKroku;
        CLI.CzyscZnak(PosX-1,PosY);
      end loop;
      CLI.Print_Klient(PosX,PosY);  ---Stoi w wyjsciu
      delay CzasKroku*5;
      CLI.CzyscZnak(PosX,PosY);

      LICZBA_KLIENTOW_W_BANKU := LICZBA_KLIENTOW_W_BANKU - 1;
      CLI.Print_LOG("Obecnie w banku jest" & LICZBA_KLIENTOW_W_BANKU'Img & " klientow" , LOG_Zdarzenie);
    end loop;
  end Klient;

---- 4.3 Obsluga
  task body Obsluga is
    nr_pracownika: Integer;
    PosX: Integer;
    PosY: Integer;
    DoceloweStanowisko: Pozycja;
    Byla_przerwa: Boolean := False;

    GodzinaPrzerwy: Integer;

    Gen: Generator; -- z pakietu Ada.Numerics.Float_Random

    Szczescie: Float;
    Doswiadczenie: Float := 1.0;

    procedure Przerwa is
    begin
      CLI.CzyscZnak(PosX+1,PosY);
      PosY := PosY - 1;
      CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
      delay CzasKroku;
      CLI.CzyscZnak(PosX+1,PosY);
      PosY := PosY - 1;
      CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
      delay CzasKroku;


      if PosX < 50 then -- dokad ma isc
        if PosX > Pokoj_Obslugi1.X then
          while (PosX /= Pokoj_Obslugi1.X) loop
            CLI.CzyscZnak(PosX+1,PosY);
            PosX := PosX - 1;    --idzie w lewo
            CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
            delay CzasKroku;
          end loop;  --jest nad st
        else
          while (PosX /= Pokoj_Obslugi1.X) loop
            CLI.CzyscZnak(PosX+1,PosY);
            PosX := PosX + 1;    --idzie w prawo
            CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
            delay CzasKroku;
          end loop;  --jest nad st
        end if;

      else
        if PosX > Pokoj_Obslugi2.X then
          while (PosX /= Pokoj_Obslugi2.X) loop
            CLI.CzyscZnak(PosX+1,PosY);
            PosX := PosX - 1;    --idzie w lewo
            CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
            delay CzasKroku;
          end loop;  --jest nad st
        else
          while (PosX /= Pokoj_Obslugi2.X) loop
            CLI.CzyscZnak(PosX+1,PosY);
            PosX := PosX + 1;    --idzie w prawo
            CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
            delay CzasKroku;
          end loop;  --jest nad st
        end if;
      end if;

      CLI.CzyscZnak(PosX+1,PosY);
      PosY := PosY - 1;
      CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
      delay CzasKroku;
      CLI.CzyscZnak(PosX+1,PosY);
      PosY := PosY - 1;
      CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
      delay CzasKroku;
      --w tym momencie chyba stoi w wejsciu do pokoju obslugi
      CLI.CzyscZnak(PosX+1,PosY); -- i tam znika
      delay 15.0*60.0*CzasKroku;

      -- pracownik wraca do stanowiska
      if DoceloweStanowisko.X <= Stanowisko3.X then    --punkt startowy dla obslugi
        PosX := Pokoj_Obslugi1.X;
        PosY := Pokoj_Obslugi1.Y;
      else
        PosX := Pokoj_Obslugi2.X;
        PosY := Pokoj_Obslugi2.Y;
      end if;
      CLI.Print_Obsluga(PosX,PosY,nr_pracownika);

      delay CzasKroku;
      CLI.CzyscZnak(PosX+1,PosY);
      PosY := PosY + 1;
      CLI.Print_Obsluga(PosX,PosY,nr_pracownika);

      delay CzasKroku;

      if PosX > DoceloweStanowisko.X then
        while (PosX /= DoceloweStanowisko.X) loop
          CLI.CzyscZnak(PosX+1,PosY);
          PosX := PosX - 1;    --idzie w lewo
          CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
          delay CzasKroku;
        end loop;  --jest nad st
      else
        while (PosX /= DoceloweStanowisko.X) loop
          CLI.CzyscZnak(PosX+1,PosY);
          PosX := PosX + 1;    --idzie w prawo
          CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
          delay CzasKroku;
        end loop;  --jest nad st
      end if;

      CLI.CzyscZnak(PosX+1,PosY);
      PosY := PosY + 1;
      CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
      delay CzasKroku;
      CLI.CzyscZnak(PosX+1,PosY);
      PosY := PosY + 1;
      CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
      delay CzasKroku;

    end Przerwa;

  begin
    accept Start;   --przypisanie id obslugi
    Reset(Gen);

    loop
      select
        accept IdzStanowisko (Sta: in Pozycja; numer: in Integer) do
          nr_pracownika := numer;

          GodzinaPrzerwy := 9+nr_pracownika;
          Byla_przerwa := False;

          DoceloweStanowisko := Sta;
          CLI.Print_LOG("Nowy Pracownik numer"& numer'Img & " idzie do stanowiska " & Sta.Nr_porzadkowy'Img , ChcePozycjeLOG("LOG_Zdarzenie",DoceloweStanowisko));  --Printowanie do loga komunikatow
        end IdzStanowisko;


        if DoceloweStanowisko.X <= Stanowisko3.X then    --punkt startowy dla obslugi
          PosX := Pokoj_Obslugi1.X;
          PosY := Pokoj_Obslugi1.Y;
        else
          PosX := Pokoj_Obslugi2.X;
          PosY := Pokoj_Obslugi2.Y;
        end if;
        CLI.Print_Obsluga(PosX,PosY,nr_pracownika);

        delay CzasKroku;
        CLI.CzyscZnak(PosX+1,PosY);
        PosY := PosY + 1;
        CLI.Print_Obsluga(PosX,PosY,nr_pracownika);

        delay CzasKroku;

        if PosX > DoceloweStanowisko.X then
          while (PosX /= DoceloweStanowisko.X) loop
            CLI.CzyscZnak(PosX+1,PosY);
            PosX := PosX - 1;    --idzie w lewo
            CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
            delay CzasKroku;
          end loop;  --jest nad st
        else
          while (PosX /= DoceloweStanowisko.X) loop
            CLI.CzyscZnak(PosX+1,PosY);
            PosX := PosX + 1;    --idzie w prawo
            CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
            delay CzasKroku;
          end loop;  --jest nad st
        end if;

        CLI.CzyscZnak(PosX+1,PosY);
        PosY := PosY + 1;
        CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
        delay CzasKroku;
        CLI.CzyscZnak(PosX+1,PosY);
        PosY := PosY + 1;
        CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
        delay CzasKroku;
        --o 2 w dol i jest na miejscu

        CLI.Print_LOG("P_Nr" & nr_pracownika'Img, ChcePozycjeLOG("LOG_ST",DoceloweStanowisko));  -- printowanie numerka
        CLI.Print_LOG("Stanowisko wolne" , ChcePozycjeLOG("LOG_STString",DoceloweStanowisko));

        -- zgloszenie kontrolerowi o stanie gotowosci
        Kontroler.ZglosWolneStanowisko(nr_pracownika);

      or
        -- od klienta
        accept Sprawa(Czas_sprawy: Integer; nr_klienta: Integer; rodzaj: Rodzaj_klienta) do
          CLI.Print_LOG("Przyjeto kienta nr" & nr_klienta'Img & " typu " & rodzaj'Img, ChcePozycjeLOG("LOG_STString",DoceloweStanowisko)); --ss

          Szczescie := Random(Gen) *1.5 +0.5; -- przedzial od 0.5 do 2.0

          delay Duration(Float(Czas_sprawy)*Doswiadczenie*Szczescie*Float(CzasKroku));

        end Sprawa;
        delay CzasKroku*180; -- cos tam jeszcze zalatwia

        if Godzina >= GodzinaPrzerwy and Byla_przerwa = False then
          CLI.Print_LOG("Pracownik na przerwie" , ChcePozycjeLOG("LOG_STString",DoceloweStanowisko));
          Przerwa;
          Byla_przerwa := True;
        end if;

        CLI.Print_LOG("Stanowisko wolne" , ChcePozycjeLOG("LOG_STString",DoceloweStanowisko));
        Kontroler.ZglosWolneStanowisko(nr_pracownika); -- i zglasza gotowosc

      or
        accept JakieStan (odp : out Pozycja) do
          odp:= DoceloweStanowisko;
        end JakieStan;
      or
        accept IdzWyjscie;
        -- to samo co dla przerwy
        CLI.CzyscZnak(PosX+1,PosY);
        PosY := PosY - 1;
        CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
        delay CzasKroku;
        CLI.CzyscZnak(PosX+1,PosY);
        PosY := PosY - 1;
        CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
        delay CzasKroku;

        if PosX < 50 then -- dokad ma isc
          if PosX > Pokoj_Obslugi1.X then
            while (PosX /= Pokoj_Obslugi1.X) loop
              CLI.CzyscZnak(PosX+1,PosY);
              PosX := PosX - 1;    --idzie w lewo
              CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
              delay CzasKroku;
            end loop;  --jest nad st
          else
            while (PosX /= Pokoj_Obslugi1.X) loop
              CLI.CzyscZnak(PosX+1,PosY);
              PosX := PosX + 1;    --idzie w prawo
              CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
              delay CzasKroku;
            end loop;  --jest nad st
          end if;

        else
          if PosX > Pokoj_Obslugi2.X then
            while (PosX /= Pokoj_Obslugi2.X) loop
              CLI.CzyscZnak(PosX+1,PosY);
              PosX := PosX - 1;    --idzie w lewo
              CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
              delay CzasKroku;
            end loop;  --jest nad st
          else
            while (PosX /= Pokoj_Obslugi2.X) loop
              CLI.CzyscZnak(PosX+1,PosY);
              PosX := PosX + 1;    --idzie w prawo
              CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
              delay CzasKroku;
            end loop;  --jest nad st
          end if;
        end if;

        CLI.CzyscZnak(PosX+1,PosY);
        PosY := PosY - 1;
        CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
        delay CzasKroku;
        CLI.CzyscZnak(PosX+1,PosY);
        PosY := PosY - 1;
        CLI.Print_Obsluga(PosX,PosY,nr_pracownika);
        delay CzasKroku;
        --w tym momencie chyba stoi w wejsciu do pokoju obslugi
        CLI.CzyscZnak(PosX+1,PosY); -- i tam znika


      end select;
    end loop;
  end Obsluga;

---- 4.4 Kontroler
  task body Kontroler is

    Numer_porzadkowy: Integer; -- ten numer dostanie nowy klient

    Numer_pracownika: Integer;
    Klient_do_ruszenia: integer;

    Kolejka_klientow: FIFO_Type;
    Kolejka_obslugi: FIFO_Type;

    Temp_pozycja: Pozycja;
  begin
    accept Start; -- w sumie to nie wiem po co to jest - LIKE A PRO !!
    Numer_porzadkowy := 1;

    loop
      select
        accept PobierzBilet(nr: out Integer) do
          nr := Numer_porzadkowy;
        end PobierzBilet;
        Numer_porzadkowy := Numer_porzadkowy+1;

      or
        accept ZglosOczekiwanieKlienta(nrKlienta: Integer) do
          Klient_do_ruszenia := nrKlienta;
        end ZglosOczekiwanieKlienta;

        if(Is_Empty (Kolejka_obslugi)) then
          Push (Kolejka_klientow, Klient_do_ruszenia);
        else
          Pop (Kolejka_obslugi, Numer_pracownika); -- pobranie numeru pracownika
          TabPracownicy(Numer_pracownika).JakieStan(Temp_pozycja); -- pobranie stanowiska do tempa
          TabKlientow(Klient_do_ruszenia).IdzStanowisko(Temp_pozycja,Numer_pracownika);
          -- "Idz pan nr xyz tam gdzie siedzi pracownik nr abc!"
        end if;

      or
        accept ZglosWolneStanowisko(nr_pracownika: Integer) do
          Numer_pracownika := nr_pracownika;
        end ZglosWolneStanowisko;

        if(Is_Empty (Kolejka_klientow)) then
          Push (Kolejka_obslugi, Numer_pracownika);
        else
          Pop (Kolejka_klientow, Klient_do_ruszenia);  -- pobranie numeru klienta
          TabPracownicy(Numer_pracownika).JakieStan(Temp_pozycja); -- pobranie stanowiska do tempa
          TabKlientow(Klient_do_ruszenia).IdzStanowisko(Temp_pozycja,Numer_pracownika);
          -- "Te! Cho no tu!"
        end if;
      or
        accept CzyscKolejke;
        loop
          if Is_Empty(Kolejka_obslugi) then
            exit;
          end if;
          Pop(Kolejka_obslugi,Numer_pracownika);
        end loop;
      end select;
    end loop;
  end Kontroler;

-- 4.5 Spawner obslugi
  task body SpawnerObslugi is
    Nr_PorzadkowyPracownika: Integer := 1;
    Numerek_losowy: Integer;

    Gen: Generator;

  begin
    accept Start;
    Reset(Gen);

    loop
      Nr_PorzadkowyPracownika := 1;
      loop -- spawnowanie pracowników do wszystkich stanowisk

        Numerek_losowy := 1 + integer(5.0 * (Random(Gen)));

        if TabStanowiska(Numerek_losowy).Wolna then
          TabPracownicy(Nr_PorzadkowyPracownika).Start;
          TabPracownicy(Nr_PorzadkowyPracownika).IdzStanowisko(Sta   => TabStanowiska(Numerek_losowy),
                                                               numer => Nr_PorzadkowyPracownika);
          TabStanowiska(Numerek_losowy).Wolna := false;
          Nr_PorzadkowyPracownika:=Nr_PorzadkowyPracownika+1;
        end if;
        delay CzasKroku*5;
        if Nr_PorzadkowyPracownika = 7 then
          exit;
        end if;
      end loop;

      Do_fajrantu_loop : -- czekaj aż do godziny fajrantu
        while Godzina < 18 loop
          delay CzasKroku*60;
        end loop Do_fajrantu_loop;

      Kontroler.CzyscKolejke;

      TabPracownicy(1).IdzWyjscie;
      TabPracownicy(2).IdzWyjscie;
      TabPracownicy(3).IdzWyjscie;
      TabPracownicy(4).IdzWyjscie;
      TabPracownicy(5).IdzWyjscie;
      TabPracownicy(6).IdzWyjscie;

      Bank_zamkniety_loop:
        while Godzina /= 9 loop
          delay CzasKroku*60;
      end loop Bank_zamkniety_loop;
    end loop;


  end SpawnerObslugi;

-- 4.6 Spawner klientow
  task body SpawnerKlientow is
    Nr_PorzadkowyKlienta: Integer := 1;

    Czas_do_spawnu: Float;
    Gen: Generator;

    package Value_Functions is new Ada.Numerics.Generic_Elementary_Functions (
     Float);
    use Value_Functions;

    function gauss return Float is
      sig : Float := 1.8;
      mi  : Float := 13.0;
      pi  : Float := 3.14159265359;
      x   : Float;
      res : Float;
    begin -- gauss
      x := Float(Godzina) + Float(Minuta)/60.0;
      res := 10.0/(sig*Sqrt(2.0*pi)) *Exp((-(x-mi)**2)/(2.0*sig*sig));
      return res;
    end gauss;

  begin
    accept Start;
    Reset(Gen);

    Array_Loop :
    for I in TabKlientow'Range loop
      TabKlientow(I).Start(I);
    end loop Array_Loop;

    loop
      if Godzina >= 9 and Godzina < 17 then -- klienci przychodzą od 9:00 do 17:00

        -- co 90 sekund średnio pojawia się klient, przedział od 60 do 120 sekund
        Czas_do_spawnu := 60.0/gauss + 60.0 * (Random(Gen));
        if LICZBA_KLIENTOW_W_BANKU <= 13 then
          if Terminal.Wolna then

            Wait_loop :
            while Czas_do_spawnu > 0.0 loop

              delay CzasKroku*2;
              Czas_do_spawnu := Czas_do_spawnu - 2.0;
            end loop Wait_loop;

            TabKlientow(Nr_PorzadkowyKlienta).IdzTerminal;

            Nr_PorzadkowyKlienta:=Nr_PorzadkowyKlienta+1;

            if Nr_PorzadkowyKlienta >= 15 then
              Nr_PorzadkowyKlienta := 1;
            end if;

          end if;
        end if;
        delay CzasKroku;

      end if;
      delay CzasKroku*600;
    end loop;
  end SpawnerKlientow;

--#################################
-- 5. Procedura glowna

  Zn : Character;
  Dummy : Boolean;

-- czas pracy od 9:00 do 18:00

begin
  CLI.Start;
  Kontroler.Start;
  SpawnerObslugi.Start;
  SpawnerKlientow.Start;

  -- zaczynamy o 9-tej rano
  Godzina := 9;
  Minuta  := 0;
  Sekunda := 0;

  loop
    delay 2.0;

    Get_Immediate(Zn,Dummy); -- Dummy co by get nie blokowal dalszych instrukcji
    if Dummy then
      if Zn = Ada.Characters.Latin_1.ESC then -- obsluga wyjscia z programu
        exit;
      elsif Zn = '+' and WybranaSkala < 10  then -- obsluga ustawiania skali czasowej
        WybranaSkala := WybranaSkala  + 1;
        CzasKroku := Duration(1.0/Skale(WybranaSkala));
        CLI.Print_LOG("Nowa skala czasowa: x" & Skale(WybranaSkala)'Img, LOG_Zdarzenie);
      elsif Zn = '-' and WybranaSkala > 1 then
        WybranaSkala := WybranaSkala - 1;
        CzasKroku := Duration(1.0/Skale(WybranaSkala));
        CLI.Print_LOG("Nowa skala czasowa: x" & Skale(WybranaSkala)'Img, LOG_Zdarzenie);
      end if;
      Zn := Ada.Characters.Latin_1.NUL;
      Dummy := False;
    end if;


    -- Podstawowy zegar
    Sekunda := Sekunda + Integer(2.0/CzasKroku);
    if Sekunda >= 60 then
      Minuta := Minuta + 1;
      Sekunda := Sekunda - 60;
    end if;

    if Minuta >= 60 then
      Godzina := Godzina + 1;
      Minuta := Minuta - 60;
    end if;

    if Godzina >= 24 then
      Godzina := 0;
    end if;

    CLI.wypiszCzas(Godzina, Minuta);
  end loop;

  CLI.Print_LOG("Koniec programu!",(1,1,41,false));
  GNAT.OS_Lib.OS_Exit (0);
end Projekt;
