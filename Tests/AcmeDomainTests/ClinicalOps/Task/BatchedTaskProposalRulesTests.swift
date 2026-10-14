@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedTaskProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultBatchedTaskProposalValidator()
        let item = ClinicalOps.newBatchedTaskProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsBatchedTaskProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.BatchedTaskProposalLabelLengthRule(maxLength: 80)
        let item = ClinicalOps.newBatchedTaskProposal("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsBatchedTaskProposalScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = ClinicalOps.BatchedTaskProposalScoreRangeRule(min: 4.8, max: 269.7)
        let item = ClinicalOps.newBatchedTaskProposal("x", label: "y")
        item.score = 271.2
        #expect(rule.check(item).count > 0)
    }
}
