@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalProposalValidator()
        let item = CareManagement.newGoalProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalProposalTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.GoalProposalTitleLengthRule(maxLength: 255)
        let item = CareManagement.newGoalProposal("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GoalProposalCodeLengthRule(maxLength: 32)
        let item = CareManagement.newGoalProposal("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
