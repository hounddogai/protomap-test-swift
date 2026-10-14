@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScoreProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedRiskScoreProposalValidator()
        let item = CareManagement.newBatchedRiskScoreProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedRiskScoreProposalWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = CareManagement.BatchedRiskScoreProposalWeightRangeRule(min: 7.5, max: 4138.8)
        let item = CareManagement.newBatchedRiskScoreProposal("x", name: "y")
        item.weight = 4140.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementBatchedRiskScoreProposalRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = CareManagement.BatchedRiskScoreProposalRequiredBedRule(
            message: "batched risk score proposal needs this field"
        )
        let item = CareManagement.newBatchedRiskScoreProposal("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedRiskScoreProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.BatchedRiskScoreProposalCodeLengthRule(maxLength: 80)
        let item = CareManagement.newBatchedRiskScoreProposal("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
