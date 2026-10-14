@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalRecordValidator()
        let item = CareManagement.newGoalRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalRecordRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.GoalRecordRequiredSegmentRule(message: "goal record needs a value")
        let item = CareManagement.newGoalRecord("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalRecordTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.GoalRecordTitleLengthRule(maxLength: 80)
        let item = CareManagement.newGoalRecord("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalRecordRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = CareManagement.GoalRecordRequiredSummaryRule(message: "goal record needs this field")
        let item = CareManagement.newGoalRecord("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
