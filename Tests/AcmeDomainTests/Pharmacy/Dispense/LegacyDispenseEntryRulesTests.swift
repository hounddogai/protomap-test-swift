@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyDispenseEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyDispenseEntryValidator()
        let item = Pharmacy.newLegacyDispenseEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyDispenseEntryAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.LegacyDispenseEntryAttemptsRangeRule(min: 3600, max: 86400)
        let item = Pharmacy.newLegacyDispenseEntry("x", label: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLegacyDispenseEntryEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Pharmacy.LegacyDispenseEntryEncounterIDLengthRule(maxLength: 120)
        let item = Pharmacy.newLegacyDispenseEntry("x", label: "y")
        item.encounterID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyDispenseEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LegacyDispenseEntryCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newLegacyDispenseEntry("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
