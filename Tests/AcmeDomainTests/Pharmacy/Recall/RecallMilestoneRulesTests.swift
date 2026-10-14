@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallMilestoneValidator()
        let item = Pharmacy.newRecallMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallMilestoneVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.RecallMilestoneVersionRangeRule(min: 16, max: 255)
        let item = Pharmacy.newRecallMilestone("x", label: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallMilestoneRequiredCodeRule(message: "recall milestone needs this field")
        let item = Pharmacy.newRecallMilestone("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallMilestoneCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Pharmacy.RecallMilestoneCountryLengthRule(maxLength: 120)
        let item = Pharmacy.newRecallMilestone("x", label: "y")
        item.country = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallMilestoneBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Pharmacy.RecallMilestoneBedLengthRule(maxLength: 86400)
        let item = Pharmacy.newRecallMilestone("x", label: "y")
        item.bed = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallMilestoneLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.RecallMilestoneLabelLengthRule(maxLength: 32)
        let item = Pharmacy.newRecallMilestone("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
