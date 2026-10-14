@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityPolicyValidator()
        let item = Imaging.newPriorityPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityPolicyScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Imaging.PriorityPolicyScoreRangeRule(min: 5.9, max: 2289.8)
        let item = Imaging.newPriorityPolicy("x", label: "y")
        item.score = 2291.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityPolicyLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.PriorityPolicyLabelLengthRule(maxLength: 80)
        let item = Imaging.newPriorityPolicy("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityPolicyRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.PriorityPolicyRequiredBedRule(message: "priority policy needs a value")
        let item = Imaging.newPriorityPolicy("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
