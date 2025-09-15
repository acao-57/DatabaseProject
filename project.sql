drop table if exists spotify cascade; 
drop table if exists tracks cascade; 
drop table if exists tga cascade;
drop table if exists artists cascade; 
drop table if exists genre cascade;
drop table if exists album cascade;

-- (Q2) Initial Schema (CREATE TABLE ...)

create table spotify
(
    id text, -- unique identifier for the track on Spotify.
    track_name text,--: name of the track.
    genre text, --: genre of the song.
    artists text, --: names of the artists who performed the track, separated by commas if there are multiple artists.
    album text, --: name of the album the track belongs to.
    popularity integer, --: popularity score of the track (0-100, where higher is more popular).
    duration_ms integer, --: duration of the track in milliseconds.
    e_content text --: boolean indicating whether the track contains explicit content.       
);

-- (Q2) Load data into the table (\copy ...)

\copy spotify FROM '/home/m10915583/spotify_tracks.csv' WITH (FORMAT CSV, HEADER true);

-- (Q4) Normalized schemas (CREATE TABLE ...)

create table tracks
(
    track_id text not null,
    track_name text not null,
    popularity integer not null,
    duration_ms integer not null,
    e_content text not null     
);

create table artists
(
    artist_id integer generated always as identity,
    artist_name text not null
);

create table tga   --cross-reference table
(
    track_id text,
    genre_id integer,
    album_id integer,
    artist_id integer
);

create table genre
(
    genre_id integer generated always as identity, 
    genre_name text not null
);

create table album
(
    album_id integer generated always as identity,
    album_name text
);

-- (Q5) Loading data from the initial table into the normalized tables  (INSERT INTO ... SELECT ...)

insert into tracks(track_id, track_name, popularity, duration_ms, e_content) 
select distinct id, track_name, popularity, duration_ms, e_content from spotify
where id is not null and track_name is not null and popularity is not null
and duration_ms is not null and e_content is not null
order by id asc;

with artists_split as
(
    select distinct regexp_split_to_table(spotify.artists, ', ') 
    as aclean from spotify 
    order by aclean asc
)
insert into artists(artist_name) select aclean from artists_split;

with genre_clean as
(
    select distinct upper(genre) as gclean from spotify 
    order by gclean asc
)
insert into genre(genre_name) select gclean from genre_clean;

with album_clean as
(
    select distinct album as al_clean from spotify 
    order by album asc
)
insert into album(album_name) select al_clean from album_clean;

insert into tga(track_id, genre_id, album_id, artist_id) 
select distinct s.id, g.genre_id, al.album_id, a.artist_id from spotify as s
cross join unnest(string_to_array(s.artists, ', ')) as names
join artists as a on names = a.artist_name
join genre as g on upper(s.genre) = g.genre_name
join album as al on s.album = al.album_name
where s.id is not null and a.artist_id is not null and g.genre_id is not null and al.album_name is not null
order by s.id;

-- (Q6) Keys and constraints (ALTER TABLE ... ADD CONSTRAINT ...)

alter table tracks 
add constraint pk_tracks_id primary key(track_id),
add constraint chk_duration_positive check(duration_ms>0),
add constraint chk_popularity_range check(popularity between 0 and 100);

alter table genre
add constraint pk_genre_id primary key(genre_id),
add constraint uk_genre_name unique(genre_name);

alter table artists
add constraint pk_artist_id primary key(artist_id);

alter table album
add constraint pk_album_id primary key(album_id),
add constraint uk_album_name unique(album_name);

alter table tga
add constraint pk_tga primary key(track_id, artist_id, genre_id, album_id),
add constraint fk_tracks_id foreign key(track_id) references tracks(track_id),
add constraint fk_genre_id foreign key(genre_id) references genre(genre_id),
add constraint fk_album_id foreign key(album_id) references album(album_id),
add constraint fk_track_id foreign key(artist_id) references artists(artist_id);


-- (Q7) Interesting Queries (SELECT ...)
explain(analyze, buffers)
select tga1.track_id, tga1.album_id, tga1.genre_id from tga as tga1
join tga as tga2 on (tga2.track_id = tga1.track_id and  tga2.album_id = tga1.album_id and tga2.genre_id <> tga1.genre_id)
group by tga1.track_id, tga1.album_id, tga1.genre_id order by tga1.track_id asc;

explain(analyze, buffers)
with genre_popularity as
(
    select distinct g.genre_name, t.track_name, t.popularity, 
    rank() over (partition by g.genre_id order by t.popularity desc) as genre_rank --orders the genres by popularity
    from tracks as t 
    join tga on t.track_id = tga.track_id
    join genre as g on tga.genre_id = g.genre_id
)
select genre_name, track_name, popularity from genre_popularity where genre_rank <=3
order by genre_name, popularity desc;

explain(analyze, buffers)
select a.artist_name, t.track_name, max(t.duration_ms/60000) as longest_track from tracks as t
join tga on t.track_id = tga.track_id
join artists as a on tga.artist_id = a.artist_id
group by a.artist_name, t.track_id
order by longest_track desc;

-- (Q8) Indexes and performance tuning (CREATE INDEX ...)

CREATE INDEX idx_tga_track_album_genre ON tga(track_id, album_id, genre_id);
CREATE INDEX idx_tracks_duration_include ON tracks(track_id, duration_ms) INCLUDE (track_name);

explain(analyze, buffers)
select tga1.track_id, tga1.album_id, tga1.genre_id from tga as tga1
join tga as tga2 on (tga2.track_id = tga1.track_id and  tga2.album_id = tga1.album_id and tga2.genre_id <> tga1.genre_id)
group by tga1.track_id, tga1.album_id, tga1.genre_id order by tga1.track_id asc;

explain (analyze, buffers)
with genre_popularity as
(
    select distinct g.genre_name, t.track_name, t.popularity, 
    rank() over (partition by g.genre_id order by t.popularity desc) as genre_rank --orders the genres by popularity
    from tracks as t 
    join tga on t.track_id = tga.track_id
    join genre as g on tga.genre_id = g.genre_id
)
select genre_name, track_name, popularity from genre_popularity where genre_rank <=3
order by genre_name, popularity desc;

explain(analyze, buffers)
select a.artist_name, t.track_name, max(t.duration_ms/60000) as longest_track from tracks as t
join tga on t.track_id = tga.track_id
join artists as a on tga.artist_id = a.artist_id
group by a.artist_name, t.track_id
order by longest_track desc;
