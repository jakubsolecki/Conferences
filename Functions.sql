--Functions
--zwraca liste uczestnikow kazdego dnia konferencji
CREATE FUNCTION function_partiticipantsOfDayConference(@ConferenceDayID int)
returns table 
as
return(
	select p.FirstName, p.LastName, '' as 'Company'
	from Person as p
		inner join IndividualClient as ic
			on ic.PersonID = p.PersonID
		inner join DayParticipant as dp
			on dp.PersonID = p.PersonID
		inner join DayReservation as dr
			on dr.DayReservationID = dp.DayReservationID
		inner join ConferenceDay as cd
			on cd.ConferenceDayID = dr.ConferenceDayID 
	where cd.ConferenceDayID = @ConferenceDayID

	union
	
	select p.FirstName, p.LastName, co.CompanyName as 'Company'
	from Person as p
		inner join Employee as e
			on e.PersonID = p.PersonID
		inner join Company as co 
			on co.ClientID = e.ClientID
		inner join DayParticipant as dp
			on dp.PersonID = p.PersonID
		inner join DayReservation as dr
			on dr.DayReservationID = dp.DayReservationID
		inner join ConferenceDay as cd
			on cd.ConferenceDayID = dr.ConferenceDayID 
	where cd.ConferenceDayID = @ConferenceDayID

)
go


--lista warsztatow dla konferencji
create function function_workshopsDuringConference(@conf_id int)
	returns table
	as
	return (
		select conf.ConferenceName, cd.ConferenceDate, wd.WorkshopName, 
			w.StartTime, w.EndTime
		from Conferences as conf
			inner join ConferenceDay as cd 
				on cd.ConferenceID = conf.ConferenceID
			inner join Workshop as w 
				on w.ConferenceDayID = cd.ConferenceDayID
			inner join WorkshopDictionary as wd 
				on wd.WorkshopDictionaryID = w.WorkshopDictionaryID
		where conf.Cancelled = 0 and w.Cancelled = 0 and conf.ConferenceID = @conf_id
	)
go


--zwraca liste uczestnikow danego warsztatu
create function function_participantsOfWorkshop(@WorkshopID int)
	returns table	
	as
	return(
		select p.FirstName, p.LastName, '' as 'Company'
		from Person as p
			inner join IndividualClient as ic
				on ic.PersonID = p.PersonID
			inner join DayParticipant as dp
				on dp.PersonID = p.PersonID
			inner join WorkshopParticipant as wp
				on wp.DayParticipantID = dp.DayParticipantID
			inner join WorkshopReservation as wr
				on wr.WorkshopReservationID = wp.WorkshopReservationID
			where wr.WorkshopID = @WorkshopID

		union 
		
		select p.FirstName, p.LastName, co.CompanyName as 'Company'
		from Person as p
			inner join Employee as e
				on e.PersonID = p.PersonID
			inner join Company as co
				on co.ClientID = e.ClientID
			inner join DayParticipant as dp
				on dp.PersonID = p.PersonID
			inner join WorkshopParticipant as wp
				on wp.DayParticipantID = dp.DayParticipantID
			inner join WorkshopReservation as wr
				on wr.WorkshopReservationID = wp.WorkshopReservationID
			where wr.WorkshopID = @WorkshopID
	)
go

--lista uczestnikow konferencji (do identyfikatorow)
create function function_participantListForConference(@conf_id int)
	returns table
	as
	return (
		select p.FirstName, p.LastName, 
			iif(com.CompanyName is not null, com.CompanyName, '') as 'Company Name'
		from person as p
			left outer join Employee as e 
				on e.PersonID = p.PersonID
			left outer join Company as com 
				on com.ClientID = e.ClientID
			inner join DayParticipant as dp 
				on dp.PersonID = p.PersonID
			inner join DayReservation as dr 
				on dr.DayReservationID = dp.DayReservationID
			inner join ConferenceDay as cd 
				on cd.ConferenceDayID = dr.ConferenceDayID
			inner join Conferences as conf 
				on conf.ConferenceID = cd.ConferenceID
		where conf.ConferenceID = @conf_id
	)
go


--top X firm wg  zakupionych biletow
create function function_topCompaniesByTickets(@x int)
	returns table 
	as
	return (
		select top(@x) com.CompanyName, 
			sum(dr.NormalTickets) 
			+ 
			sum(dr.StudentTickets) 
			as 'Total number of tickets'
		from Company as com
			inner join Clients as cl 
				on cl.ClientID = com.ClientID
			inner join Reservation as r 
				on r.ClientID = cl.ClientID
				and r.PaymentDate is not null
			inner join DayReservation as dr 
				on dr.ResevationID = r.ResevationID
		group by com.CompanyName
		order by 2 desc
	)
go


--top x firm wg rezerwacji
create function function_topCompaniesByReservations(@x int)
	returns table 
	as
	return (
		select top(@x) com.CompanyName
		from Company as com
			inner join Clients as cl 
				on cl.ClientID = com.ClientID
			inner join Reservation as r 
				on r.ClientID = cl.ClientID
				and r.PaymentDate is not null
		group by com.CompanyName
		order by count(r.ResevationID) desc
)
go

