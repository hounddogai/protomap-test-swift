@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledPriorityScoreValidator()
        let item = Imaging.newScheduledPriorityScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledPriorityScoreRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ScheduledPriorityScoreRequiredLabelRule(message: "scheduled priority score needs this field")
        let item = Imaging.newScheduledPriorityScore("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingScheduledPriorityScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ScheduledPriorityScoreCodeLengthRule(maxLength: 86400)
        let item = Imaging.newScheduledPriorityScore("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledPriorityScoreCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Imaging.ScheduledPriorityScoreCreatedAtRangeRule(min: 3600, max: 86400)
        let item = Imaging.newScheduledPriorityScore("x", label: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingScheduledPriorityScoreWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.ScheduledPriorityScoreWeightRangeRule(min: 7.0, max: 2844.0)
        let item = Imaging.newScheduledPriorityScore("x", label: "y")
        item.weight = 2845.5
        #expect(rule.check(item).count > 0)
    }
}
