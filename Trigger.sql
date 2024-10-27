USE [WideWorldImporters]
GO

/****** Object:  Trigger [Sales].[InvoiceLinesCRUDLogging]    Script Date: 27.10.2024 20:36:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:	<Mike Ussoff>
-- Create date: <2024-10-27>
-- Description:	<CRUD logging>
-- =============================================
CREATE TRIGGER [Sales].[InvoiceLinesCRUDLogging]
   ON  [Sales].[InvoiceLines] 
   AFTER INSERT, DELETE, UPDATE
   NOT FOR REPLICATION
AS 
BEGIN
	IF @@ROWCOUNT = 0 RETURN;
	SET NOCOUNT ON; 

	-- insert (TypeOp = 1)
	INSERT INTO Sales.InvoiceLinesLogs (QueuedOn, SentOn, TypeOp, InvoiceLineID, InvoiceID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen)
	SELECT getutcdate(), null, 1, i.InvoiceLineID, i.InvoiceID, i.StockItemID, i.[Description], i.PackageTypeID, i.Quantity, i.UnitPrice, i.TaxRate, i.TaxAmount, i.LineProfit, i.ExtendedPrice, i.LastEditedBy, i.LastEditedWhen
	FROM  inserted i 
	LEFT JOIN deleted d on i.InvoiceLineID = d.InvoiceLineID
	WHERE d.InvoiceLineID is null

	-- update (TypeOp = 2)
	INSERT INTO Sales.InvoiceLinesLogs (QueuedOn, SentOn, TypeOp, InvoiceLineID, InvoiceID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen)
	SELECT getutcdate(), null, 2, i.InvoiceLineID, i.InvoiceID, i.StockItemID, i.[Description], i.PackageTypeID, i.Quantity, i.UnitPrice, i.TaxRate, i.TaxAmount, i.LineProfit, i.ExtendedPrice, i.LastEditedBy, i.LastEditedWhen
	FROM  inserted i 
	INNER JOIN deleted d on i.InvoiceLineID = d.InvoiceLineID

	-- delete (TypeOp = 3)
	INSERT INTO Sales.InvoiceLinesLogs (QueuedOn, SentOn, TypeOp, InvoiceLineID, InvoiceID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen)
	SELECT getutcdate(), null, 3, d.InvoiceLineID, d.InvoiceID, d.StockItemID, d.[Description], d.PackageTypeID, d.Quantity, d.UnitPrice, d.TaxRate, d.TaxAmount, d.LineProfit, d.ExtendedPrice, d.LastEditedBy, d.LastEditedWhen
	FROM  deleted d 
	LEFT JOIN inserted i on i.InvoiceLineID = d.InvoiceLineID
	WHERE i.InvoiceLineID is null
END
GO

ALTER TABLE [Sales].[InvoiceLines] ENABLE TRIGGER [InvoiceLinesCRUDLogging]
GO


