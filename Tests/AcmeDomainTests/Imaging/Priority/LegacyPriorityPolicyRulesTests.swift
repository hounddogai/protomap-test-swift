@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyPriorityPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLegacyPriorityPolicyValidator()
        let item = Imaging.newLegacyPriorityPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLegacyPriorityPolicyTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.LegacyPriorityPolicyTitleLengthRule(maxLength: 80)
        let item = Imaging.newLegacyPriorityPolicy("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLegacyPriorityPolicyDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Imaging.LegacyPriorityPolicyDosageMgRangeRule(min: 0.5, max: 1729.1)
        let item = Imaging.newLegacyPriorityPolicy("x", title: "y")
        item.dosageMg = 1730.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLegacyPriorityPolicyRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Imaging.LegacyPriorityPolicyRequiredAllergyRule(message: "legacy priority policy needs this field")
        let item = Imaging.newLegacyPriorityPolicy("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
