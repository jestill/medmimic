## Instantiating a test database for PCORnet Common Data Model v 3.0

These data were initally generated as an [ESP fake data model](https://popmednet.atlassian.net/wiki/pages/viewpage.action?pageId=26345558) and were
converted into a PCORI data model.

To load the data.

1. run create_pcori_cdmv3_tables.sql to create the tables
2. copy csv tables to the /tmp directory
3. run load_pcori_cdmv3_tables.sql
4. index_pcori_cdmv3_tables.sql

This process has be successfully tested on:

* PostgreSQL 9.3.5 on x86_64-apple-darwin