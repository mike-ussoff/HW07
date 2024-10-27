USE [WideWorldImporters]
GO

/****** Object:  StoredProcedure [Sales].[InvoiceLinesReplication]    Script Date: 27.10.2024 20:35:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Mike Ussoff>
-- Create date: <2024-10-27>
-- Description:	<Replication to Postgres>
-- =============================================
CREATE PROCEDURE [Sales].[InvoiceLinesReplication] 
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

-- удалить старые записи
	DECLARE @deathline DateTime;
	SELECT @deathline = DATEADD(DAY, -1, getdate());
	DELETE FROM [Sales].[InvoiceLinesLogs] WHERE SentOn < @deathline;

	DROP TABLE IF EXISTS #InvoiceLinesIDs;
	SELECT Id INTO #InvoiceLinesIDs FROM Sales.InvoiceLinesLogs WHERE SentOn is null ;

-- вставка (TypeOp = 1)
	INSERT INTO pg_wwi.wideworldimporters.sales.invoicelines 
	(InvoiceLineID, InvoiceID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen)
	SELECT InvoiceLineID, InvoiceID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen
	FROM Sales.InvoiceLinesLogs WHERE TypeOp = 1 and Id in (select Id from #InvoiceLinesIDs);
	UPDATE Sales.InvoiceLinesLogs  SET SentOn = getutcdate() WHERE TypeOp = 1 and Id in (select Id from #InvoiceLinesIDs);
	
-- обновление (TypeOp = 2)
	UPDATE dest SET 
	dest.InvoiceID = src.InvoiceID, 
	dest.StockItemID = src.StockItemID, 
	dest.[Description] = src.[Description], 
	dest.PackageTypeID = src.PackageTypeID, 
	dest.Quantity = src.Quantity, 
	dest.UnitPrice = src.UnitPrice, 
	dest.TaxRate = src.TaxRate, 
	dest.TaxAmount = src.TaxAmount, 
	dest.LineProfit = src.LineProfit, 
	dest.ExtendedPrice = src.ExtendedPrice, 
	dest.LastEditedBy = src.LastEditedBy, 
	dest.LastEditedWhen = src.LastEditedWhen
	FROM pg_wwi.wideworldimporters.sales.invoicelines dest
	INNER JOIN 
	(
		SELECT i.*, row_number() OVER (PARTITION BY i.InvoiceLineId ORDER BY i.Id DESC) as Num
		FROM Sales.InvoiceLinesLogs i 
		INNER JOIN #InvoiceLinesIDs tmp ON tmp.Id = i.Id AND i.TypeOp = 2
	) src ON src.InvoiceLineID = dest.InvoiceLineID and src.Num = 1 and src.Id in (select Id from #InvoiceLinesIDs);
	UPDATE Sales.InvoiceLinesLogs  SET SentOn = getutcdate() WHERE TypeOp = 2 and Id in (SELECT Id FROM #InvoiceLinesIDs);

-- удаление  (TypeOp = 3)
	DELETE FROM pg_wwi.wideworldimporters.sales.invoicelines WHERE InvoiceLineID in 
	(SELECT InvoiceLineID FROM Sales.InvoiceLinesLogs WHERE TypeOp = 3 and Id in (SELECT Id FROM #InvoiceLinesIDs)) 
	UPDATE Sales.InvoiceLinesLogs  SET SentOn = getutcdate() WHERE TypeOp = 3 and Id in (SELECT Id FROM #InvoiceLinesIDs);
  
	DROP TABLE #InvoiceLinesIDs;
END
GO


