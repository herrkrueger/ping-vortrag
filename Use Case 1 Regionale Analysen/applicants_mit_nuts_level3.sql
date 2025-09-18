sql

SELECT
    tls206_person.person_name AS applicant,
    tls206_person.nuts AS nuts_code,
    tls201_appln.appln_filing_year AS filing_year,
    tls224_appln_cpc.cpc_class_symbol AS cpc_subclass,
    COUNT(DISTINCT tls201_appln.appln_id) AS appln_count
FROM
    tls201_appln
    INNER JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
    INNER JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
    INNER JOIN tls224_appln_cpc ON tls201_appln.appln_id = tls224_appln_cpc.appln_id
WHERE
    tls206_person.nuts LIKE 'DE%' AND
    tls206_person.nuts_level = 3 AND
    tls201_appln.appln_filing_year >= EXTRACT(YEAR FROM CURRENT_DATE()) - 10
GROUP BY
    tls206_person.person_name,
    tls206_person.nuts,
    tls201_appln.appln_filing_year,
    tls224_appln_cpc.cpc_class_symbol
ORDER BY
    tls206_person.nuts, tls201_appln.appln_filing_year, appln_count DESC;
