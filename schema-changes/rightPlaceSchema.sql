-- DO NOT run this query in Production!!! this is only for generate Plan
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_ciqCompany_Company_Type')
BEGIN
  CREATE NONCLUSTERED INDEX IX_ciqCompany_Company_Type ON dbo.ciqCompany (companyTypeId)
  INCLUDE (companyId) WITH (ONLINE=ON);
END
