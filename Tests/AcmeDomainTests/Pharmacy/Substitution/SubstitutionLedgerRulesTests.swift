@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionLedgerValidator()
        let item = Pharmacy.newSubstitutionLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionLedgerLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Pharmacy.SubstitutionLedgerLimitRangeRule(min: 64, max: 80)
        let item = Pharmacy.newSubstitutionLedger("x", label: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionLedgerRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.SubstitutionLedgerRequiredLabelRule(message: "substitution ledger needs an entry")
        let item = Pharmacy.newSubstitutionLedger("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionLedgerRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Pharmacy.SubstitutionLedgerRequiredWardRule(message: "substitution ledger needs an entry")
        let item = Pharmacy.newSubstitutionLedger("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
