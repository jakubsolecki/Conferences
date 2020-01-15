--Procedures

create procedure procedure_addWorkshopToDictionary
	@WorkshopName varchar(50),
	@WorkshopDescription varchar(255),
	@Price money
as
begin
	set nocount on
	insert into WorkshopDictionary (
		WorkshopName,
		WorkshopDescription,
		Price
	)
	VALUES (
		@WorkshopName,
		@WorkshopDescription,
		@Price
	)
end
go


create procedure procedure_addWorkshop
	@WorkshopDictionaryID int,
    @Date date,
    @ConferenceID int,
	@StartTime time,
	@EndTime time,
	@Limit int
as
begin
	set nocount on
	Declare @ConferenceDayID int = dbo.function_returnConferenceDay(@ConferenceID, @Date);
	begin try
		if  (@ConferenceDayID is null)
		begin
			;throw 52000, 'Conference day does not exist', 1
        end

		if not exists (
			select * from WorkshopDictionary
			where WorkshopDictionaryID = @WorkshopDictionaryID
		)
		begin
			;throw 52000, 'Workshop does not exist in dictionary',1
		end
		if (@StartTime > @EndTime)
		begin
			;throw 52000, 'Start time cannot be bigger than End time', 1
		end

		Declare @Price money = dbo.function_returnValueOfWorkshop(@WorkshopDictionaryID);

	insert into Workshop (
		WorkshopDictionaryID,
		ConferenceDayID,
		StartTime,
		EndTime,
		Limit,
		Price
		)
		VALUES (
			@WorkshopDictionaryID,
			@ConferenceDayID,
			@StartTime,
			@EndTime,
			@Limit,
			@Price
		)
	end try
	begin catch
		declare @errorMessage nvarchar(2048) =
		'Cannot add workshop. Error message: ' + ERROR_MESSAGE();
		;throw 52000, @errorMessage, 1;
	end catch
end
go


create procedure procedure_addCountry
	@countryName varchar(50)
as
begin
	set nocount on
	begin try
		if exists (
			select country
			from Country
			where Country = @countryName
		)
		begin
			;throw 52000, 'Country exists', 1
		end
		insert into Country (
			Country
		)
		values (
			@countryName
		)
	end try
	begin catch
		declare @errorMsg nvarchar(2048)
			= 'Cannot add country. Error message: '
			+ error_message();
		;throw 52000, @errorMsg, 1
	end catch
end 
go
	

create procedure procedure_addCity
	@cityName varchar(50),
	@countryName varchar(50)
as
begin
	set nocount on
	begin try
		if(@cityName is null or @countryName is null) 
			begin
				;throw 52000,  'Podaj nazwe miasta i kraju', 1
			end 
		if not exists (
			select *
			from Country
			where Country = @countryName
		)
			begin
				exec procedure_addCountry 
						@countryName
			end
		if not exists (
			select * 
			from City
			where city = @cityName
		)
			begin
				insert into City (
					City,
					CountryID
				)
				values (
					@cityName,
					(
					select countryID
					from Country
					where Country = @countryName
					)
				)
			end
	end try
	begin catch 
		declare @errorMsg nvarchar(2048)
			= 'Cannot add city. Error message: '
			+ error_message();
		;throw 52000, @errorMsg, 1
	end catch
end
go


create procedure procedure_addConferenceDay
	@conferenceID int,
	@conferenceDate date
as
begin
	begin try
		if(@conferenceID is null or
		   @conferenceDate is null
		  )
			begin
				;throw 52000,  'Podaj wszystkie parametry.', 1
			end

		insert into ConferenceDay (
			ConferenceID,
			ConferenceDate
		)
		values (
			@conferenceID,
			@conferenceDate
		)
	end try

	begin catch 
		declare @errorMsg nvarchar(2048)
			= 'Cannot add conference day. Error message: '
			+ error_message();
		;throw 52000, @errorMsg, 1
	end catch
end
go


create procedure procedure_addConference
	@conferenceName varchar(50),
	@conferenceDescription varchar(255),
	@startDate date,
	@endDate date,
	@cityName varchar(50),
	@countryName varchar(50),
	@street varchar(50),
	@buildingNumber varchar(10),
	@studentDiscount real,
	@limit int,
	@basePrice money
as
begin
	set nocount on
	begin try 

		if (@conferenceName is null or
			@conferenceDescription is null or
			@startDate is null or
			@endDate is null or
			@cityName is null or
			@countryName is null or
			@street is null or
			@buildingNumber is null or
			@studentDiscount is null or
			@limit is null or
			@basePrice is null
		)
			begin
				;throw 52000,  'Podaj wszystkie parametry.', 1
			end

		if (@startDate <= getdate())
			begin
				;throw 52000, 'Data rozpocz�cia musi by� p�zniejsza ni� 
							   dzisiejsza', 1
			end

		if (@startDate >@endDate)
			begin
				;throw 52000, 'Data rozpocz�cia musi by� p�niejsza ni�
							   data zako�czenia', 1
			end

		if(@studentDiscount < 0 or @studentDiscount > 1)
			begin
				;throw 52000, 'Zni�ka musi by� z przedzia�u [0,1]', 1
			end

		if not exists (
			select * 
			from City
			where City = @cityName and
				CountryID = (
					select CountryID
					from Country
					where Country = @countryName
				)
		)
			begin
				exec procedure_addCity
						@cityName,
						@countryName
			end

		begin
			insert into Conferences (
				ConferenceName,
				ConferenceDescription,
				StartDate,
				EndDate,
				CityID,
				Street,
				BuildingNumber,
				StudentDiscount,
				Limit,
				BasePrice
			)
			values (
				@conferenceName,
				@conferenceDescription,
				@startDate,
				@endDate,
				(
					 select CityID
					 from City
					 where city = @cityName and
						CountryID = (
						select CountryID
						from Country
						where Country = @countryName
					)
				),
				@street,
				@buildingNumber,
				@studentDiscount,
				@limit,
				@basePrice
			)
		end

		declare @conferenceID int
		set @conferenceID = @@identity
		declare @d date = @startDate

		while @d <= @endDate
			begin
				exec procedure_addConferenceDay
						@conferenceID,
						@d

				set @d = dateadd(d, 1, @d)
			end
	end try

	begin catch 
		declare @errorMsg nvarchar(2048)
			= 'Cannot add conference. Error message: '
			+ error_message();
		;throw 52000, @errorMsg, 1
	end catch

end
go


create procedure procedure_addPriceThreshold
	@conferenceID int,
	@startDate date,
	@discount real
as
begin
	set nocount on
	begin try
		if (@conferenceID is null or
			@startDate is null or
			@discount is null
		)
			begin
				;throw 52000, 'Podaj wszystkie parametry', 1
			end

		if(@discount <= 0 or @discount >= 1)
			begin
				;throw 52000, 'Zni�ka musi by� z przedzia�u (0,1)', 1
			end

		if(@discount + (
		    select StudentDiscount
		    from Conferences
		    where @conferenceID = ConferenceID
        ) >= 1)
		    begin
                ;throw 52000, 'Znizka ogolna wraz ze studencka nie moga razem wynosci >= 100%', 1
            end

		if(@startDate < getdate())
			begin
				;throw 52000, 'Nie mo�esz ustali� progu w przesz�o�ci', 1
			end

		if not exists (
			select *
			from Conferences
			where conferenceID = @conferenceID
		)
			begin
				;throw 52000, 'Nie ma takiej konferencji', 1
			end

		if(@startDate > (
		    select StartDate
		    from Conferences
		    where ConferenceID = @conferenceID
        ))
			begin
				;throw 52000, 'Data rozpocz�cia musi by�
							   przed dat� konferencji', 1
			end

		if exists (
		    select *
		    from Prices
		    where StartDate = @startDate
        )
		    begin
                ;throw 52000, 'Prog o tej dacie juz istnieje', 1
            end

		insert into Prices (
			ConferenceID,
			StartDate,
			Discount
		)
		values (
			@conferenceID,
			@startDate,
			@discount
		)
	end try

	begin catch 
		declare @errorMsg nvarchar(2048)
			= 'Cannot add price treshold. Error message: '
			+ error_message();
		;throw 52000, @errorMsg, 1
	end catch
end 
go


create procedure procedure_deletePriceTreshold
	@priceID int
as
begin
	set nocount on
	begin try
		if(@priceID is null)
			begin
				;throw 52000, 'Podaj ID progu cenowego', 1
			end

		if not exists (
			select * 
			from Prices
			where PriceID = @priceID
		)
			begin
				;throw 52000, 'Podany prog cenowy nie istnieje.', 1
			end

		delete Prices	
			where PriceID = @priceID
	end try

	begin catch 
		declare @errorMsg nvarchar(2048)
			= 'Cannot delete price treshold. Error message: '
			+ error_message();
		;throw 52000, @errorMsg, 1
	end catch

end
go


create procedure procedure_addIndividualClient
	@phone varchar(9),
	@street varchar(50),
	@buildingNumber varchar(10),
	@cityName varchar(50),
	@countryName varchar(50),
	@email varchar(50),
	@firstName varchar(50),
	@lastName varchar(50),
	@studnetCardID varchar(50)
as
begin
	set nocount on
	begin try
		if (@phone is null or
			@street is null or
			@buildingNumber is null or
			@cityName is null or
			@countryName is null or
			@email is null or
			@firstName is null or
			@lastName is null
		)
			begin
				;throw 52000, 'Podaj wszystkie dane 
							   (nr legitymacji jest opcjonalny).', 1
			end

		if not exists (
			select * 
			from city
			where city = @cityName and
				CountryID = (
					select CountryID
					from Country
					where Country = @countryName
				)
		)
			begin
				exec procedure_addCity
						@cityName,
						@countryName
			end

		if exists (
			select * 
			from Clients
			where Email = @email
		)
			begin
				;throw 52000, 'Adres email jest ju� wykorzystany', 1
			end

			insert into Clients (
			Phone,
			Street,
			BuildingNumber,
			CityID,
			Email
		)
		values (
			@phone,
			@street,
			@buildingNumber,
			(
				select CityID 
				from City
				where City = @cityName and
				CountryID = (
					select CountryID
					from Country
					where Country = @countryName	
				)
			),
			@email
		)

		declare @clientID int
		set @clientID = @@identity

		insert into Person default values
		declare @personID int
		set @personID = @@identity


		insert into IndividualClient (
			ClientID,
			PersonID,
			FirstName,
			LastName
		)
		values (
			@clientID,
			@personID,
			@firstName,
			@lastName
		)

		if(@studnetCardID is not null)
			begin
				if exists (
					select * 
					from Student
					where StudentCardID = @studnetCardID
				)
					begin
						;throw 52000, 'Ten numer legitymacji istnieje ju� w bazie', 1
					end

				insert into Student (
					StudentCardID,
					PersonID
				)
				values (
					@studnetCardID,
					@personID
				)
			end
	end try

	begin catch 
		declare @errorMsg nvarchar(2048)
			= 'Cannot add individual client. Error message: '
			+ error_message();
		;throw 52000, @errorMsg, 1
	end catch
end
go


create procedure procedure_addCompany
	@Phone varchar(9),
	@Street varchar(50),
	@CityName varchar(50),
	@Country varchar(50),
	@BuildingNumber varchar(10),
	@Email varchar(50),
	@Nip varchar(50),
	@CompanyName varchar(50)
as
begin
	set nocount on
	begin try 
		if (
			@Phone is null or 
			@Street is null or
			@CityName is null or
			@BuildingNumber is null or
			@Email is null or
			@Nip is null or
			@CompanyName is null
		)
			begin
				;throw 52000, 'Podaj wszystkie parametry', 1
			end
		if exists(
			select * from Clients
			where Email like @Email
		)
			begin
				;throw 52000, 'Adres email jest juz wykorzystany',1 
			end

		if not exists (
			select * 
			from City
			where City = @CityName  and
				CountryID = (
					select CountryID
					from Country
					where Country = @Country	
				)
		)
			begin
				exec procedure_addCity @CityName, @Country
			end

		insert into Clients (
			Phone,
			Street,
			BuildingNumber,
			CityID,
			Email
		)
		values (
			@Phone,
			@Street,
			@BuildingNumber,
			(
				select CityID
				from City
				where city = @cityName and
				CountryID = (
					select CountryID
					from Country
					where Country = @Country	
				)
			),
			@Email
		)

		declare @ClientID int
		set @ClientID = @@identity

		insert into Company (
			ClientID,
			CompanyName,
			NIP
		)
		values(
			@ClientID,
			@CompanyName,
			@Nip
		)
	end try
	begin catch 
		declare @errorMessage nvarchar(2048)
			= 'Cannot add CompanyClient. Error message: '
			+ error_message();
		;throw 52000, @errorMessage, 1
	end catch
end
go


create procedure procedure_addIndividualReservation
	@ClientID int,
	@ConferenceID int,
	@DayList IndividualReservation READONLY
as
begin
set nocount on
	begin try 
		if (
			@ClientID is null or
			@ConferenceID is null
		)
		begin
			;throw 52000, 'Podaj wszystkie parametry', 1
		end
		--sprawdzam czy client istnieje
		if not exists(select * from Clients where ClientID = @ClientID)
		begin
            ;throw 52000, 'Client does not exists', 1
        end
		--sprawdzam czy client jest ind
		if not exists(select * from Clients as c inner join IndividualClient IC on c.ClientID = IC.ClientID where c.ClientID = @ClientID)
		begin
            ;throw 52000, 'Client is not individual', 1
        end
        --sprawdzam czy konferncja istnieje
		if not exists(select * from Conferences where ConferenceID = @ConferenceID)
		begin
            ;throw 52000, 'Conference does not exists', 1
        end

		--sprawdza czy uzytkownik zrobil rezerwacji na dany dzien konferencji

		if exists (
		    select * from Reservation as r
		        inner join DayReservation DR on r.ReservationID = DR.ReservationID
		        inner join ConferenceDay CD on DR.ConferenceDayID = CD.ConferenceDayID
		    where CD.ConferenceID = @ConferenceID and r.ClientID = @ClientID
        )
		begin
            ;throw 52000, 'User has already booked this Conference', 1
        end

	    declare @iterator int = 1;
		declare @max int = (select count(*) from @DayList);
		if (@max <= 0)
		begin
            ;throw 52000, 'DayList cannot be empty', 1
        end
		declare @day date;
		while (@iterator <= @max)
		begin
		    set @day = (select ConferenceDate from @DayList where ID = @iterator)
            if (dbo.function_returnConferenceDay(
                @ConferenceID, @day) is null)
		    begin
                ;throw 52000, 'Conference day does not exists', 1
            end
		    set @iterator = @iterator + 1;
        end
		insert into Reservation(
			ClientID,
			ReservationDate
		)
		values(
			@ClientID,
			GETDATE()
		)
		declare @ReservationID int = @@IDENTITY;
		set @iterator = 1;
		while (@iterator <= @max)
		begin
		    set @day = (select ConferenceDate from @DayList where ID = @iterator)
		    declare @ConferenceDayID int = dbo.function_returnConferenceDay (@ConferenceID, @day)
            exec procedure_addIndividualDayReservation @ReservationID, @ConferenceDayID;
		    set @iterator = @iterator + 1;
        end
	end try

	begin catch
		declare @errorMessage nvarchar(2048)
			= 'Cannot add Reservation. Error message: '
			+ error_message();
		;throw 52000, @errorMessage, 1
	end catch
end
go


create procedure procedure_addDayParticipant
	@PersonID int,
	@DayReservationID int
as
begin
	set nocount on
	begin try
	if (
		@PersonID is null or
		@DayReservationID is null
	)
	begin
		;throw 52000, 'Podaj wszystkie parametry', 1
	end
	insert into DayParticipant(
		PersonID,
		DayReservationID
	)
	VALUES(
		@PersonID,
		@DayReservationID
	)
	end try 
	begin catch
		declare @errorMessage nvarchar(2048)
			= 'Cannot add DayParticipant. Error message: '
			+ error_message();
		;throw 52000, @errorMessage, 1
	end catch
end
go


create procedure procedure_addIndividualDayReservation
	@ReservationID int,
	@ConferenceDayID int
as
begin
	set nocount on
	begin try
		if (
			@ConferenceDayID is null
			or @ReservationID is null
		)
		begin
			;throw 52000, 'Podaj wszystkie parametry', 1
		end


		if exists(
			select * from DayReservation
			where ReservationID = @ReservationID and ConferenceDayID = @ConferenceDayID
		)
		begin 
			;throw 52000, 'User has already booked this day of conference', 1
		end

		declare @reservationPersonID int;
		set @reservationPersonID = dbo.function_returnPersonID(@ReservationID);

		--sprawdza czy klient jest studentem jak jest to daje mu bilet ulgowy
		declare @StudentTickets int;
		declare @NormalTickets int;
		if exists (
			select * from Person
			inner join Student on Student.PersonID = Person.PersonID
			where @reservationPersonID = Person.PersonID
		)
		begin
			set @StudentTickets = 1;
			set @NormalTickets = 0;
		end
		else
		begin
			set @StudentTickets = 0;
			set @NormalTickets = 1;
		end


		insert into DayReservation(
			ConferenceDayID,
			ReservationID,
			NormalTickets,
			StudentTickets
		)
		values(
			@ConferenceDayID,
			@ReservationID,
			@NormalTickets,
			@StudentTickets
		)

	exec procedure_addDayParticipant @reservationPersonID, @@IDENTITY
	end try 
	begin catch
		declare @errorMessage nvarchar(2048)
			= 'Cannot add DayReservation. Error message: '
			+ error_message();
		;throw 52000, @errorMessage, 1
	end catch
end
go

create procedure procedure_addCompanyReservation
    @ClientID int,
    @ConferenceID int,
    @DayList CompanyReservation READONLY,
    @StudentList StudentIDCards READONLY
as
begin
    set nocount on
    begin try
        if (@ClientID is null or @ConferenceID is null)
        begin
            ;throw 52000, 'Podaj wszystkie parametry', 1
        end

        --sprawdzam czy client istnieje
		if not exists(select * from Clients where ClientID = @ClientID)
		begin
            ;throw 52000, 'Client does not exists', 1
        end
		--sprawdzam czy client jest comp
		if not exists(select * from Clients as c inner join Company C2 on c.ClientID = C2.ClientID where c.ClientID = @ClientID)
		begin
            ;throw 52000, 'Client is not Company', 1
        end
        --sprawdzam czy konferncja istnieje
		if not exists(select * from Conferences where ConferenceID = @ConferenceID)
		begin
            ;throw 52000, 'Conference does not exists', 1
        end

		--sprawdza czy uzytkownik zrobil rezerwacje na dany dzien konferencji
		if exists (
		    select * from Reservation as r
		        inner join DayReservation DR on r.ReservationID = DR.ReservationID
		        inner join ConferenceDay CD on DR.ConferenceDayID = CD.ConferenceDayID
		    where CD.ConferenceID = @ConferenceID and r.ClientID = @ClientID
        )
		begin
            ;throw 52000, 'User has already booked this Conference', 1
        end
        declare @NStudent int = (select count(*) from @StudentList);
        declare @it int = 1;
        declare @idCard varchar(50);
        declare @studentDate date;
        while (@it <= @NStudent)
        begin
            set @idCard = (select StudentIDCard from @StudentList where ID = @it)
            set @studentDate = (select ConferenceDate from @StudentList where ID = @it)
            if exists(select * from Student where StudentCardID like @idCard)
            begin
                ;throw 52000, 'Student id card is not unique', 1;
            end
            if not exists (select * from @DayList where ConferenceDate = @studentDate)
            begin
                ;throw 52000, 'invalid student date', 1
            end
            set @it = @it + 1;
        end


        declare @iterator int =  1;
        declare @NDay int = (select count(*) from @DayList);
        if (@NDay <= 0)
        begin
            ;throw 52000, 'DayList cannot be empty', 1
        end

        declare @day date;
        while (@iterator <= @NDay)
		begin
		    set @day = (select ConferenceDate from @DayList where ID = @iterator)
            if (dbo.function_returnConferenceDay(
                @ConferenceID, @day) is null)
		    begin
                ;throw 52000, 'Conference day does not exists', 1
            end
		    set @iterator = @iterator + 1;
        end

        insert into Reservation(
            ClientID,
            ReservationDate
        ) VALUES (@ClientID, GETDATE())
        declare @ReservationID int = @@IDENTITY
        set @iterator = 1;
        declare @normalTickets int;
        declare @ConferenceDayID int;
        declare @StudentTickets int;
        declare @sIterator int;
        declare @studentIDCard varchar(50);
        declare @DayReservationID int;
        while (@iterator <= @NDay)
        begin
            set @day = (select ConferenceDate from @DayList where ID = @iterator);
            set @ConferenceDayID = dbo.function_returnConferenceDay (@ConferenceID, @day)
            set @normalTickets = (select NormalTickets from @DayList where ID = @iterator);
            set @studentTickets = (select count(*) from @StudentList where ConferenceDate = @day);
            exec procedure_addCompanyDayReservation @ReservationID, @ConferenceID, @normalTickets, @StudentTickets
            set @DayReservationID = @@IDENTITY;
            set @sIterator = 1;
            while (@sIterator <= @NStudent)
            begin
                set @studentIDCard = null;
                set @studentIDCard = (select StudentIDCard from @StudentList where ConferenceDate = @day and ID = @sIterator);
                if (@studentIDCard is not null and isnumeric(@studentIDCard) = 1)
                begin
                    exec procedure_initializeEmployee @DayReservationID, @studentIDCard;
                end
                set @sIterator = @sIterator + 1;
            end


            set @sIterator = 1;
            while (@sIterator <= @normalTickets)
            begin
                exec procedure_initializeEmployee @DayReservationID, null
                set @sIterator = @sIterator + 1;
            end
            set @iterator = @iterator + 1;
        end
    end try
    begin catch
		declare @errorMessage nvarchar(2048)
			= 'Cannot add Reservation. Error message: '+ error_message();
		;throw 52000, @errorMessage, 1
	end catch
end
go


create procedure procedure_addCompanyDayReservation
	@ReservationID int,
    @ConferenceDayID int,
	@NormalTickets int,
	@StudentTickets int
as
begin
	set nocount on
	begin try
		if (
			@ReservationID is null or
			@ConferenceDayID is null or
			@NormalTickets is null or 
			@StudentTickets is null
		)
		begin
			;throw 52000, 'Podaj wszystkie parametry', 1
		end

		if (@ConferenceDayID is null)
		begin 
			;throw 52000, 'Conference does not exist', 1
		end

		insert into DayReservation(
			ConferenceDayID,
			ReservationID,
			NormalTickets,
			StudentTickets
		)
		values(
			@ConferenceDayID,
			@ReservationID,
			@NormalTickets,
			@StudentTickets
		)
	end try 
	begin catch
		declare @errorMessage nvarchar(2048)
			= 'Cannot add DayReservation. Error message: '+ error_message();
		;throw 52000, @errorMessage, 1
	end catch
end
go

create procedure procedure_initializeEmployee
	@DayReservationID int,
	@StudentIDCard varchar(50)
as
begin
	set nocount on
	begin try
		if (
			@DayReservationID is null
		)
		begin
			;throw 52000, 'Podaj wszystkie parametry', 1
		end

		declare @ReservationID int = (select ReservationID from DayReservation where DayReservationID = @DayReservationID);
		declare @ClientID int;
		set @ClientID = (select ClientID from Reservation where ReservationID = @ReservationID)

		if not exists (select * from Company where ClientID = @ClientID)
		begin 
			;throw 52000, 'Reservation is not made by company', 1
		end

		insert into Person default values
		declare @PersonID int = @@IDENTITY;
		insert into Employee(
			ClientID,
			PersonID,
			FirstName,
			LastName
		)
		VALUES(
			@ClientID,
			@PersonID,
			null,
			null
		)
		if (@StudentIDCard is not null)
		begin 
			insert into Student(
				StudentCardID,
				PersonID
			)
			values(
				@StudentIDCard,
				@PersonID
			)
		end
		

		exec procedure_addDayParticipant @PersonID, @DayReservationID
	end try 
	begin catch
		declare @errorMessage nvarchar(2048)
			= 'Cannot InitializeEmployee. Error message: '
			+ error_message();
		;throw 52000, @errorMessage, 1
	end catch
end
go



create procedure procedure_addEmployee
	@personID int,
	@firstName varchar(50),
	@lastName varchar(50)	
as
begin
	set nocount on
	begin try
		
		if (@personID is null or
			@firstName is null or
			@lastName is null
		)
			begin
				;throw 52000, 'Podaj wszystkie dane', 1
			end
	
		if not exists (
			select * 
			from Employee
			where PersonID = @personID
		)
			begin
				;throw 52000, 'Osoba o tym ID nie istnieje', 1
			end

		update Employee
		set FirstName = @firstName, LastName = @lastName
		where PersonID = @personID


	end try
	begin catch 
		declare @errorMessage nvarchar(2048)
			= 'Cannot add employee. Error message: '
			+ error_message();
		;throw 52000, @errorMessage, 1
	end catch
end
go

create procedure procedure_addWorkshopReservation
	@WorkshopID int, 
	@DayReservationID int,
	@Tickets int
as
begin
	set nocount on
	begin try
		
		if (@WorkshopID is null or
			@DayReservationID is null or
			@Tickets is null
		)
		begin
			;throw 52000, 'Podaj wszystkie dane', 1
		end
		
		if not exists (select * from DayReservation where DayReservationID = @DayReservationID)
		begin
			;throw 52000, 'Day Reservation does not exist', 1
		end

		if not exists (select * from Workshop where WorkshopID = @WorkshopID)
		begin
			;throw 52000, 'Workshop does not exist', 1
		end

		declare @isIndividual bit;
		if exists ( 
			select * from DayReservation as dr 
			inner join Reservation as r 
					on dr.ReservationID = r.ReservationID
			inner join Clients as c
				on c.ClientID = r.ClientID
			inner join IndividualClient as ic
				on ic.ClientID = c.ClientID
			where DayReservationID = @DayReservationID
		)
		begin
			set @isIndividual = 1;
		end
		else
		begin
			set @isIndividual = 0;
		end

		if (@Tickets <= 0)
		begin
			;throw 52000, 'Number of tickets has to be greater than 0', 1
		end

		if (@isIndividual = 1 and @Tickets <> 1)
		begin
			;throw 52000, 'Individual client can buy only one ticket', 1
		end

		insert into WorkshopReservation (
			WorkshopID,
			DayReservationID,
			Tickets
		)
		values (
			@WorkshopID,
			@DayReservationID,
			@Tickets
		)

	end try
	begin catch 
		declare @errorMessage nvarchar(2048)
			= 'Cannot add WorkshopReservation. Error message: '
			+ error_message();
		;throw 52000, @errorMessage, 1
	end catch
end
go

create procedure procedure_addWorkshopParticipant
	@PersonID int,
	@WorkshopReservationID int
as
begin
	set nocount on
	begin try
		
		if (
			@PersonID is null or
			@WorkshopReservationID is null
		)
		begin
			;throw 52000, 'Podaj wszystkie dane', 1
		end

		if not exists (select * from Person where PersonID = @PersonID)
		begin
			;throw 52000, 'Person does not exist', 1
		end

		if not exists (select * from WorkshopReservation where WorkshopReservationID = @WorkshopReservationID)
		begin 
			;throw 52000, 'WorkshopReservation does not exist', 1
		end

		 
		declare @DayReservationID int = (
			select DayReservationID from WorkshopReservation 
			where WorkshopReservationID = @WorkshopReservationID
		)

		if not exists (
			select * from DayParticipant
			where PersonID = @PersonID 
				and DayReservationID = @DayReservationID
		)
		begin 
			;throw 52000, 'Person cannot be a participant of workshop when Person is not a particiapnt of conference', 1
		end

		declare @DayParticiapntID int = (
			select DayParticipantID from DayParticipant
			where PersonID = @PersonID and DayReservationID = @DayReservationID
		)

		insert into WorkshopParticipant(
			DayParticipantID,
			WorkshopReservationID
		)
		values(
			@DayParticiapntID,
			@WorkshopReservationID
		)

	end try
	begin catch 
		declare @errorMessage nvarchar(2048)
			= 'Cannot add Workshop Participant. Error message: '
			+ error_message();
		;throw 52000, @errorMessage, 1
	end catch
end 
go

create procedure procedure_addPayment
	@ReservationID int
as
begin
	set nocount on
	begin try
		if (
			@ReservationID is null
		)
		begin
			;throw 52000, 'Podaj wszystkie parametry', 1
		end
	
		if not exists (
			select * from Reservation where ReservationID = @ReservationID
		)
		begin
			;throw 52000, 'Reservation does not exist', 1
		end

		if exists (
			select * from Reservation 
			where ReservationID = @ReservationID 
				and PaymentDate is not null
		)
		begin
			;throw 52000, 'Reservation has already been paid', 1
		end

		update Reservation 
		set PaymentDate = GETDATE()
		where ReservationID = @ReservationID
	
	end try
	begin catch 
		declare @errorMessage nvarchar(2048)
			= 'Cannot add Payment. Error message: '
			+ error_message();
		;throw 52000, @errorMessage, 1
	end catch
end
go

	


