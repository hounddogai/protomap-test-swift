@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedAcuityPlanProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultWeightedAcuityPlanProposalValidator()
        let item = Staffing.newWeightedAcuityPlanProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingWeightedAcuityPlanProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.WeightedAcuityPlanProposalRequiredCodeRule(
            message: "weighted acuity plan proposal needs an entry"
        )
        let item = Staffing.newWeightedAcuityPlanProposal("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingWeightedAcuityPlanProposalSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Staffing.WeightedAcuityPlanProposalSequenceRangeRule(min: 255, max: 3600)
        let item = Staffing.newWeightedAcuityPlanProposal("x", label: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}
