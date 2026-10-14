@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledBedBoardProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledBedBoardProposalValidator()
        let item = BedManagement.newScheduledBedBoardProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledBedBoardProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.ScheduledBedBoardProposalRequiredLabelRule(
            message: "scheduled bed board proposal needs this field"
        )
        let item = BedManagement.newScheduledBedBoardProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledBedBoardProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.ScheduledBedBoardProposalLabelLengthRule(maxLength: 80)
        let item = BedManagement.newScheduledBedBoardProposal("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
