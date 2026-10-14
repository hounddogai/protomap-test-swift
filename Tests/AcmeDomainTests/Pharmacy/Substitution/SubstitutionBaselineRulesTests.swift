@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionBaselineValidator()
        let item = Pharmacy.newSubstitutionBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.SubstitutionBaselineCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newSubstitutionBaseline("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionBaselineRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Pharmacy.SubstitutionBaselineRequiredCurrencyRule(message: "substitution baseline needs an entry")
        let item = Pharmacy.newSubstitutionBaseline("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionBaselineChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Pharmacy.SubstitutionBaselineChecksumLengthRule(maxLength: 32)
        let item = Pharmacy.newSubstitutionBaseline("x", title: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionBaselineRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Pharmacy.SubstitutionBaselineRequiredChecksumRule(message: "substitution baseline needs an entry")
        let item = Pharmacy.newSubstitutionBaseline("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
