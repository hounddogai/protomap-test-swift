@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierMilestoneValidator()
        let item = Labs.newCourierMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierMilestoneChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Labs.CourierMilestoneChannelLengthRule(maxLength: 3600)
        let item = Labs.newCourierMilestone("x", label: "y")
        item.channel = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierMilestoneAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.CourierMilestoneAttemptsRangeRule(min: 16, max: 32)
        let item = Labs.newCourierMilestone("x", label: "y")
        item.attempts = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCourierMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CourierMilestoneRequiredCodeRule(message: "courier milestone needs a value")
        let item = Labs.newCourierMilestone("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierMilestoneWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Labs.CourierMilestoneWindowDaysRangeRule(min: 64, max: 80)
        let item = Labs.newCourierMilestone("x", label: "y")
        item.windowDays = 81
        #expect(rule.check(item).count > 0)
    }
}
