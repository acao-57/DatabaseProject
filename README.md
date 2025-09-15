## Q1 Dataset location and citation

Location: Kaggle
Citation:
Ambaliya, G. (2024, June 17). Spotify dataset. Kaggle. https://www.kaggle.com/datasets/ambaliyagati/spotify-dataset-for-playing-around-with-sql.  Accessed 28 Mar. 2025.

## Functional Dependencies

{id, genre} -> {name}
This is a non-trivial functional dependency because name is not a subset of id and genre. 
The track name is uniquely determined by the track's spotify id and genre.
(it's possible for there to be duplicate track ids, but these are differentiated by song genre, therefore
{id, genre} is the primary key).

{id, genre, album} -> {name, genre, album, popularity}
This is a non-trivial functional dependency because name and popularity in the right hand side are 
not in the set in the left hand side. The intersection of left and right sides is not empty, but name 
and popularity are not a subset of the left side. The track id, genre, and album determine the name of the track, 
genre of the song, the track's album, and also the popularity of the track.

{name, artists} -> {album}
This is a non-trivial functional dependency because album is not a subset of set name, artists. 
Track name and artist(s) determine the track album's title, but this violates BCNF because
{name, artists} is not a key attribute and does not uniquely determine the entire row.

## Normalized Schema

Normalize your original schema into BCNF. Include the normalized schema in your README.txt file.
Put the corresponding SQL code to create the tables in your project.sql file. You do not need to
include the derivation of the BCNF schema in your submission, but you do need to include proof
that your schema is in BCNF. You can do this by showing that the left-hand side of each functional
dependency is a superkey of the relation.

tracks
(
    track_id text,          primary key
    track_name text,
    popularity integer,
    duration_ms integer,
    e_content text      
);

{track_id} -> {track_name, album_id, popularity, duration_ms, e_content}
{track_id} has distinct values and is the primary key. there are no other non-trivial dependencies that occur where the left side is not a superkey.

tga
(
    track_id         foreign key to tracks, part of primary key
    genre_id         foreign key to genre, part of primary key
    album_id         foreign key to album, part of primary key
    artist_id        foreign key to artist table, part of primary key
);
cross reference table relating tracks, genres, and artists; a track can have multiple artists, albums, and genres.
since this is a pure junction table, {track_id, genre_id, album_id, artist_id} -> {}. 
only foreign keys form composite primary key, and no other dependencies occur.

artists
(
    artist_id         primary key
    artist_name    
);
records the name of each artist. each artist corresponds to a unique artist id
artist_id -> artist name. we can't have artist name -> artist id since artist names aren't necessarily unique. no other dependencies occur.

genre
(
    genre_id        primary key
    genre           candidate key
);
for each genre id, we have a specific genre name. corresponds name to unique genre id ina one-to-one relationship
genre_id -> genre, and genre -> genre_id. genre is a candidate key that uniquely identifies each row, and is a subset of the super key

album
(
    album_id        primary key
    album_name      candidate key
);
multiple albums can have the same name, but each album has a specific id. corresponds name to unique album id
album_id -> album_name


## Data Cleaning

Create SQL statements to clean the data and insert it into the BCNF schema. Check for missing
values, coerce datatypes, and split columns as necessary. Include the SQL code in your project.sql
file. Your statements should insert rows from the relation you created in Q2 into the BCNF schema
you created in Q4. In README.txt, explain what data cleaning you did and why it was necessary.

tracks:
in this table, I cleaned my data so that I only had distinct, non-null values. From my browsing of the dataset,
it was possible for the same id to have different genres (all other columns were constant). Knowing this,
I made tracks have a distinct id to which table tga (look further in README.txt) could retrieve all
other id information.

artists:
in this table, I first created a view that would split the original artists column if there were ', ' values,
meaning that if a song has multiple artists, each artist would have their own id. This is important because 
artists can have many songs, so having each unique artist with their own id across multiple song ids was crucial
in maintaining a many-to-many relationship. By using the keyword 'distinct', I was able to get all non-null values
as well. Used in table tga to retrieve all other id information.

genre:
in this table, I cleaned my data so that I only had distinct genre names, of which each had an id. This table is
used as an important reference from the tga table and reduces repetition. By using the keyword 'distinct', I was 
able to get all non-null values as well.

album:
same as genre.

tga:
this is an important junction table that holds the track_ids, artists_ids, genre_ids, and album_ids. There are 
multiple tracks with the same id, but different genres, different artists, and different albums. If we are looking
up a specific id from tracks for example, this table would be important in seeing the rows associated with
that id. Since this is a composite junction table, each of the rows is distinct and has no null values to prevent
identical relationship tuples.

## Keys and Constraints

Create the necessary keys and constraints for your tables. Include the SQL code in your project.sql
file. In README.txt, explain why you chose the keys and constraints you did. You should include at
least one primary key, one foreign key, and one check constraint

primary keys:
tracks_id in tracks, genre_id in genre, artist_id in artists, and album_id in album should all be primary keys
because they enforce uniqueness of the id and prevent null values. They are anchor point for any other relationship(s). 
All of the foreign keys in table tga form a composite primary key.

foreign keys:
All of the ids in the tga table are foreign keys. They are references between tables and enforce specific relationships.
Having each foreign key ensures we have valid references to existing ids/records in other tables.

constraints:
There are two specific contraints, both in the tracks table. The first makes sure that the duration of the track is greater
than 0, meaning that we can validate that we in fact have an actual track. The second relates to the range of the track's 
popularity. It validates that the popularity is in the proper range (0-100) and any outliers should be considered as invalid 
entries.

## Interesting Queries

The first query retrieves information about tracks with the same id, but different genres. It's interesting because a track
can be the same and therefore have the same id, but what differs them is that they are in different genres. For example, a 
track can have genres k-pop and j-pop, or electro and electronic, etc. It shows that tracks and songs are different in nature.

The second query ranks the top 3 track names of each genre with the highest popularity scores. If multiple top-ranking songs
have the same scores, then there may be more than 3 tracks. If we have less than 3 tracks in a genre, then only those tracks
are shown. It visualizes the popularity of each genre numerically, so we can see what the "most popular" and highest-ranking 
genres/songs are

The third query gets the longest tracks from each artist (excluding genre). This gives us insight into the longest songs in spotify
and their artist. Most of these songs appear to be study playlists or complilations of tracks, but put together into one song.
The fact that the longest tracks are 1 hour may indicate that Spotify only allows up to 1 hour for a single track as well.

## Performance Tuning

Perform two performance tuning changes to your database that positively impact some of the queries
in the previous question. At least one of these changes must be an index. Include the SQL code in your
project.sql file. In README.txt, explain what the changes are and how they affected the performance
of the query. Use EXPLAIN and its options (like ANALYZE and BUFFERS) to compare your query
performance before/after the change. Include these numbers in your response. (Remember: ways of
improving performance include reducing the runtime of the query or the number of rows/pages read,
or reducing the amount of memory used to execute the query)

my first index on tga(track_id, album_id, genre_id):
this index was specifically tuned for the first query that utilizes self-joins in the tga table.
my second index on tracks(track_id, duration_ms) INCLUDE (track_name);
this index was specifically tuned for the third query that utilized duration, track_id, and track_name

When running explain (analyze, buffers) on these specific queries there were some interesting results.
For the first query, execution time improved by about 2-3 ms, but planning time increased by 0.01-0.0.5 ms 
on average. There was an improvement in the execution time, but the tradeoff was a decreased planning time
performance. Overall runtime only slightly improved. Moreover, the results with buffer indicate a slight improvement
in cache efficiency.

There was no improvement in the second query, and the metrics got worse. This makes sense because I did performance
tuning specifically for the first and third query.

The third query had a slightly better runtime where execution time improved by 0.1-3 ms, but planning time got worse by 0.1-0.2. 
Overall there was little difference before and after the changes.


Q1 before:
    Buffers: shared hit=38
 Planning Time: 0.103 ms
 Execution Time: 8.439 ms
 
Q1 after:
   Buffers: shared hit=33 read=1
 Planning Time: 0.161 ms
 Execution Time: 6.981 ms

 Q2 before:
    Buffers: shared hit=16
 Planning Time: 0.183 ms
 Execution Time: 7.709 ms

Q2 after:
    Buffers: shared hit=30 read=1
 Planning Time: 0.276 ms
 Execution Time: 7.816 ms

Q3 before:
    Buffers: shared hit=8
 Planning Time: 0.146 ms
 Execution Time: 10.371 ms

Q3 after:
    Buffers: shared hit=83 read=6
 Planning Time: 0.390 ms
 Execution Time: 10.038 ms
