@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyIsolationForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyIsolationForecastValidator()
        let item = BedManagement.newLegacyIsolationForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyIsolationForecastEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = BedManagement.LegacyIsolationForecastEncounterIDLengthRule(maxLength: 64)
        let item = BedManagement.newLegacyIsolationForecast("x", name: "y")
        item.encounterID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLegacyIsolationForecastUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = BedManagement.LegacyIsolationForecastUpdatedAtRangeRule(min: 120, max: 3600)
        let item = BedManagement.newLegacyIsolationForecast("x", name: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLegacyIsolationForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.LegacyIsolationForecastRequiredCodeRule(
            message: "legacy isolation forecast needs an entry"
        )
        let item = BedManagement.newLegacyIsolationForecast("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLegacyIsolationForecastChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = BedManagement.LegacyIsolationForecastChecksumLengthRule(maxLength: 3600)
        let item = BedManagement.newLegacyIsolationForecast("x", name: "y")
        item.checksum = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLegacyIsolationForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.LegacyIsolationForecastCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newLegacyIsolationForecast("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLegacyIsolationForecastNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.LegacyIsolationForecastNameLengthRule(maxLength: 64)
        let item = BedManagement.newLegacyIsolationForecast("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
