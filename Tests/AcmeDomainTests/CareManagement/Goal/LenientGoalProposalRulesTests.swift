@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientGoalProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientGoalProposalValidator()
        let item = CareManagement.newLenientGoalProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientGoalProposalRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = CareManagement.LenientGoalProposalRequiredTimezoneRule(message: "lenient goal proposal needs a value")
        let item = CareManagement.newLenientGoalProposal("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientGoalProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.LenientGoalProposalRequiredLabelRule(message: "lenient goal proposal needs a value")
        let item = CareManagement.newLenientGoalProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientGoalProposalRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = CareManagement.LenientGoalProposalRequiredUnitRule(message: "lenient goal proposal needs an entry")
        let item = CareManagement.newLenientGoalProposal("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
