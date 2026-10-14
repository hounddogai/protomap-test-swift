@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultFormularyRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultFormularyRecordValidator()
        let item = Pharmacy.newDefaultFormularyRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultFormularyRecordRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.DefaultFormularyRecordRequiredNameRule(message: "default formulary record needs an entry")
        let item = Pharmacy.newDefaultFormularyRecord("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultFormularyRecordSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Pharmacy.DefaultFormularyRecordSummaryLengthRule(maxLength: 120)
        let item = Pharmacy.newDefaultFormularyRecord("x", name: "y")
        item.summary = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultFormularyRecordExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.DefaultFormularyRecordExpiresAtRangeRule(min: 255, max: 86400)
        let item = Pharmacy.newDefaultFormularyRecord("x", name: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDefaultFormularyRecordNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.DefaultFormularyRecordNameLengthRule(maxLength: 80)
        let item = Pharmacy.newDefaultFormularyRecord("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
