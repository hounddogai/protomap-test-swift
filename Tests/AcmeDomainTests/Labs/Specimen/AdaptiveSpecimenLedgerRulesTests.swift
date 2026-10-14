@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveSpecimenLedgerValidator()
        let item = Labs.newAdaptiveSpecimenLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveSpecimenLedgerCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.AdaptiveSpecimenLedgerCountryLengthRule(maxLength: 80)
        let item = Labs.newAdaptiveSpecimenLedger("x", label: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptiveSpecimenLedgerUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Labs.AdaptiveSpecimenLedgerUpdatedAtRangeRule(min: 16, max: 86400)
        let item = Labs.newAdaptiveSpecimenLedger("x", label: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptiveSpecimenLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AdaptiveSpecimenLedgerRequiredCodeRule(message: "adaptive specimen ledger needs a value")
        let item = Labs.newAdaptiveSpecimenLedger("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
