USE nAShville_housing;

SELECT *
FROM nas_housing;

-- Standardize Date Format

ALTER TABLE nas_housing
MODIFY SaleDate DATE;

-- Populate Property Address data

SELECT *
FROM nas_housing
ORDER BY ParcelID;

CREATE TABLE temp AS SELECT * FROM nas_housing;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress,b.PropertyAddress)  
FROM nas_housing a
JOIN temp b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE nas_housing, temp
SET nas_housing.PropertyAddress = IFNULL(nas_housing.PropertyAddress,temp.PropertyAddress)
WHERE nas_housing.ParcelID = temp.ParcelID AND nas_housing.UniqueID <> temp.UniqueID AND nas_housing.PropertyAddress IS NULL;

DROP TABLE temp;


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


SELECT PropertyAddress
FROM nas_housing;

SELECT
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1 ) AS Address
, SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1 , CHAR_LENGTH(PropertyAddress)) AS Address2
FROM nas_housing;

ALTER TABLE nas_housing
Add PropertySplitAddress NVARCHAR(255);

UPDATE nas_housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1 );

ALTER TABLE nas_housing
Add PropertySplitCity NVARCHAR(255);

UPDATE nas_housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1 , CHAR_LENGTH(PropertyAddress));

SELECT *
FROM nas_housing;

SELECT OwnerAddress
FROM nas_housing;

SELECT
SUBSTRING_INDEX(OwnerAddress, ',', 1)
,SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1) 
,SUBSTRING_INDEX(OwnerAddress, ',', -1)
FROM nas_housing;

ALTER TABLE nas_housing
Add OwnerSplitAddress NVARCHAR(255);

UPDATE nas_housing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE nas_housing
Add OwnerSplitCity NVARCHAR(255);

UPDATE nas_housing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1);

ALTER TABLE nas_housing
Add OwnerSplitState NVARCHAR(255);

UPDATE nas_housing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',',-1);

SELECT *
FROM nas_housing;

-- Change Y and N to Yes and No in "Sold AS Vacant" field

SELECT DISTINCT(SoldASVacant), Count(SoldASVacant)
FROM nas_housing
GROUP BY SoldASVacant
ORDER BY 2;

SELECT SoldASVacant
, CASE WHEN SoldASVacant = 'Y' THEN 'Yes'
	   WHEN SoldASVacant = 'N' THEN 'No'
	   ELSE SoldASVacant
	   END
FROM nas_housing;

UPDATE nas_housing
SET SoldASVacant = CASE WHEN SoldASVacant = 'Y' THEN 'Yes'
	   WHEN SoldASVacant = 'N' THEN 'No'
	   ELSE SoldASVacant
	   END;

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM nas_housing
)
DELETE FROM nas_housing
USING nas_housing
JOIN RowNumCTE
	ON
    nas_housing.ParcelID = RowNumCTE.ParcelID 
	AND nas_housing.PropertyAddress = RowNumCTE.PropertyAddress 
	AND nas_housing.SalePrice = RowNumCTE.SalePrice 
	AND nas_housing.SaleDate = RowNumCTE.SaleDate 
	AND nas_housing.LegalReference = RowNumCTE.LegalReference
WHERE row_num > 1;

SELECT *
FROM nas_housing;

-- Delete Unused Columns

SELECT *
FROM nas_housing;


ALTER TABLE nas_housing
DROP SaleDate,
DROP OwnerAddress,
DROP TaxDistrict,
DROP PropertyAddress;