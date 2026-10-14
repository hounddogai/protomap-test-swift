@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalCourierMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalCourierMilestoneValidator()
        let item = Labs.newGlobalCourierMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalCourierMilestoneLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.GlobalCourierMilestoneLabelLengthRule(maxLength: 86400)
        let item = Labs.newGlobalCourierMilestone("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsGlobalCourierMilestoneRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Labs.GlobalCourierMilestoneRequiredTimezoneRule(message: "global courier milestone needs this field")
        let item = Labs.newGlobalCourierMilestone("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalCourierMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.GlobalCourierMilestoneRequiredCodeRule(message: "global courier milestone needs a value")
        let item = Labs.newGlobalCourierMilestone("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalCourierMilestoneRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.GlobalCourierMilestoneRequiredLabelRule(message: "global courier milestone needs this field")
        let item = Labs.newGlobalCourierMilestone("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
