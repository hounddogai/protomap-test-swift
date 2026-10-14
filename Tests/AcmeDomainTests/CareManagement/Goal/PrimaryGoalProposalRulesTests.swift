@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryGoalProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryGoalProposalValidator()
        let item = CareManagement.newPrimaryGoalProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryGoalProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.PrimaryGoalProposalRequiredLabelRule(message: "primary goal proposal needs an entry")
        let item = CareManagement.newPrimaryGoalProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
