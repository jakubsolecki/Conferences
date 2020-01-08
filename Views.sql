--Views

CREATE VIEW view_CityInDictionary as
select c.CityID, c.City, c.CountryID, co.Country
from City as c inner join Country as co on c.CountryID = c.countryID
go


CREATE VIEW view_countriesInDictionary as 
select c.Country from Country as c
go


CREATE VIEW view_cancelledWorkshop as
select wd.WorkshopName, cd.ConferenceDate from Workshop as w
inner join WorkshopDictionary as wd
on wd.WorkshopDictionaryID = w.WorkshopDictionaryID
inner join ConferenceDay as cd
on cd.ConferenceDayID = w.ConferenceDayID
go


CREATE VIEW view_cancelledConferences as
select * 
from Conferences
where Cancelled = 1
go


--liczba wolnych/zarezerwowanych miejsc na nadchodzace konferencje
CREATE VIEW view_conferencesSeatsLeft as
select c.ConferenceID, c.ConferenceName, c.Limit, cd.ConferenceDate, 
	c.Limit -
	((select isnull(sum(dr.NormalTickets), 0)
		from DayReservation as dr 
		where dr.ConferenceDayID = cd.ConferenceDayID)
	+
	(select isnull(sum(dr.StudentTickets), 0)
		from DayReservation as dr 
		where dr.ConferenceDayID = cd.ConferenceDayID)) as 'seats left'
from Conferences as c 
	inner join ConferenceDay as cd on cd.ConferenceID = c.ConferenceID
where year(c.StartDate) > year(getdate()) 
	and month(c.StartDate) > month(getdate()) and
	day(c.StartDate) > day(getdate()) and c.Cancelled = 0
go


--wyswietla liczbe miejsc zarezerwowanych na nadchodzace warsztaty
--i calkowity limit miejsc
CREATE VIEW view_workshopsSeatLimit as 
select w.WorkshopID, wd.WorkshopName,
	cd.ConferenceDate, w.StartTime, w.EndTime, 
	SUM(wr.NormalTickets) AS 'Booked Places', w.Limit AS 'Total Places'
from WorkshopDictionary as wd
	inner join Workshop as w
		on w.WorkshopDictionaryID = wd.WorkshopDictionaryID
	inner join ConferenceDay as cd on 
		w.ConferenceDayID = cd.ConferenceDayID
	left outer join WorkshopReservation as wr
		on w.WorkshopID = wr.WorkshopID
where (cd.ConferenceDate > GETDATE() and w.Cancelled <> 1)
group by w.WorkshopID, wd.WorkshopName,
			cd.ConferenceDate, w.StartTime, w.EndTime, w.Limit
go


CREATE VIEW view_workshopDictionary as
select wd.WorkshopName, wd.WorkshopDescription, wd.Price
	from WorkshopDictionary as wd
go


--informacje o nadchodzacyh konferencjach
CREATE VIEW view_conferencesInfo as
select c.ConferenceName, c.ConferenceDescription, c.limit, c.StartDate, c.EndDate, 
	c.BuildingNumber,c.street, ci.City, co.Country, 
	c.BasePrice*(1-p.Discount) as 'Normal ticket price', 
	c.BasePrice*(1-p.Discount)*(1-c.StudentDiscount) as 'Student ticket price'
from Conferences as c
	inner join City as ci on ci.CityID = c.CityID
	inner join Country as co on co.CountryID = ci.CountryID
	inner join prices as p on p.ConferenceID = c.ConferenceID and 
		GETDATE() between p.StartDate and p.EndDate 
where year(c.StartDate) > year(getdate()) 
	and month(c.StartDate) > month(getdate()) and
	day(c.StartDate) > day(getdate()) and c.Cancelled = 0
go


--wyswietla rezerwacje kt�re powinny zosta� usuni�te
CREATE VIEW view_reservtionOnConferenceToDelete as 
select r.ResevationID, r.ClientID, dr.NormalTickets, dr.StudentTickets,
	DATEADD(day, 7, r.ReservationDate) as 'Deadline',
	c.ConferenceID, c.ConferenceName  
	from Reservation as r
	inner join DayReservation as dr 
		on dr.ResevationID = r.ResevationID
	inner join ConferenceDay as cd 
		on cd.ConferenceDayID = dr.ConferenceDayID
	inner join Conferences as c
		on c.ConferenceID = cd.ConferenceID
where PaymentDate is null and DATEDIFF(day, DATEADD(day, 7, r.ReservationDate), GETDATE()) > 0
go


--firmy, ktore nie uzupelnily wszystkich uczestnikow 2 tygodnie przed konferencja
CREATE VIEW view_companiesYetToFillEmployees as
select com.CompanyName, com.NIP, com.Email, cl.Phone
from Company as com
	inner join Clients as cl on cl.ClientID = com.ClientID
	inner join Reservation as r on r.ClientID = cl.ClientID
	inner join DayReservation as dr on dr.ResevationID = r.ResevationID
	--left outer join DayParticipant as dp on dr.DayReservationID = dp.DayReservationID 
		--and dp.PersonID is null
	inner join ConferenceDay as cd on cd.ConferenceDayID = dr.ConferenceDayID
	inner join Conferences as c on c.ConferenceID = cd.ConferenceDayID
where datediff(day, getdate(), c.StartDate) <= 14 and 
	--dr.NormalTickets + dr.StudentTickets < count(dp.PersonID)
	(dr.NormalTickets + dr.StudentTickets) < 
	(select count(dp2.personID)
		from DayParticipant as dp2
		where dp2.DayReservationID = dr.DayReservationID)
