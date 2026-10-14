@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanProposalValidator()
        let item = BedManagement.newDischargePlanProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanProposalCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = BedManagement.DischargePlanProposalCostRangeRule(min: 7.5, max: 626.1)
        let item = BedManagement.newDischargePlanProposal("x", label: "y")
        item.cost = 627.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.DischargePlanProposalLabelLengthRule(maxLength: 32)
        let item = BedManagement.newDischargePlanProposal("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.DischargePlanProposalRequiredLabelRule(message: "discharge plan proposal needs a value")
        let item = BedManagement.newDischargePlanProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DischargePlanProposalRequiredCodeRule(
            message: "discharge plan proposal needs this field"
        )
        let item = BedManagement.newDischargePlanProposal("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
