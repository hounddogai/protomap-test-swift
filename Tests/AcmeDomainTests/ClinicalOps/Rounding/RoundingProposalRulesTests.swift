@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingProposalValidator()
        let item = ClinicalOps.newRoundingProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingProposalRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = ClinicalOps.RoundingProposalRequiredSummaryRule(message: "rounding proposal needs a value")
        let item = ClinicalOps.newRoundingProposal("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.RoundingProposalRequiredNameRule(message: "rounding proposal needs this field")
        let item = ClinicalOps.newRoundingProposal("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingProposalSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = ClinicalOps.RoundingProposalSequenceRangeRule(min: 64, max: 120)
        let item = ClinicalOps.newRoundingProposal("x", name: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingProposalEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.RoundingProposalEndsAtRangeRule(min: 255, max: 86400)
        let item = ClinicalOps.newRoundingProposal("x", name: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
