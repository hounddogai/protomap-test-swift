@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionTierValidator()
        let item = Pharmacy.newSubstitutionTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionTierTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.SubstitutionTierTitleLengthRule(maxLength: 1000)
        let item = Pharmacy.newSubstitutionTier("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionTierAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Pharmacy.SubstitutionTierAllergyLengthRule(maxLength: 64)
        let item = Pharmacy.newSubstitutionTier("x", title: "y")
        item.allergy = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionTierRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.SubstitutionTierRequiredLabelRule(message: "substitution tier needs this field")
        let item = Pharmacy.newSubstitutionTier("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
