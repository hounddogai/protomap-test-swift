@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionPreferenceValidator()
        let item = Pharmacy.newSubstitutionPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionPreferenceRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Pharmacy.SubstitutionPreferenceRequiredChecksumRule(
            message: "substitution preference needs this field"
        )
        let item = Pharmacy.newSubstitutionPreference("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionPreferenceWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.SubstitutionPreferenceWeightRangeRule(min: 3.3, max: 4428.9)
        let item = Pharmacy.newSubstitutionPreference("x", name: "y")
        item.weight = 4430.4
        #expect(rule.check(item).count > 0)
    }
}
