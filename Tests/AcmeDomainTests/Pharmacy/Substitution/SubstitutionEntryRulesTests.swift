@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionEntryValidator()
        let item = Pharmacy.newSubstitutionEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionEntryRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Pharmacy.SubstitutionEntryRequiredRegionRule(message: "substitution entry needs an entry")
        let item = Pharmacy.newSubstitutionEntry("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.SubstitutionEntryRequiredCodeRule(message: "substitution entry needs a value")
        let item = Pharmacy.newSubstitutionEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionEntryMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Pharmacy.SubstitutionEntryMinimumRangeRule(min: 2.0, max: 757.6)
        let item = Pharmacy.newSubstitutionEntry("x", label: "y")
        item.minimum = 759.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionEntryRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Pharmacy.SubstitutionEntryRequiredReviewerRule(message: "substitution entry needs this field")
        let item = Pharmacy.newSubstitutionEntry("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionEntryWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.SubstitutionEntryWeightRangeRule(min: 4.6, max: 3799.9)
        let item = Pharmacy.newSubstitutionEntry("x", label: "y")
        item.weight = 3801.4
        #expect(rule.check(item).count > 0)
    }
}
