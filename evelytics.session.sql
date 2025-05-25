SELECT * FROM evelytics.INSERT INTO chrFactions (
    factionID,
    factionName,
    description,
    raceIDs,
    solarSystemID,
    corporationID,
    sizeFactor,
    stationCount,
    stationSystemCount,
    militiaCorporationID,
    iconID
  )
VALUES (
    'factionID:bigint',
    'factionName:text',
    'description:text',
    'raceIDs:bigint',
    'solarSystemID:bigint',
    'corporationID:double precision',
    'sizeFactor:double precision',
    'stationCount:double precision',
    'stationSystemCount:double precision',
    'militiaCorporationID:double precision',
    'iconID:bigint'
  );chrFactions