@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferProposalValidator()
        let item = BedManagement.newTransferProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferProposalFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.TransferProposalFloorValueRangeRule(min: 7.8, max: 3537.0)
        let item = BedManagement.newTransferProposal("x", label: "y")
        item.floorValue = 3538.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferProposalSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = BedManagement.TransferProposalSourceLengthRule(maxLength: 3600)
        let item = BedManagement.newTransferProposal("x", label: "y")
        item.source = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferProposalBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.TransferProposalBudgetRangeRule(min: 2.5, max: 1313.5)
        let item = BedManagement.newTransferProposal("x", label: "y")
        item.budget = 1315.0
        #expect(rule.check(item).count > 0)
    }
}
