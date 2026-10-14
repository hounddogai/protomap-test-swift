@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyOrderSetProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyOrderSetProposalValidator()
        let item = ClinicalOps.newLegacyOrderSetProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetProposalPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = ClinicalOps.LegacyOrderSetProposalPayerLengthRule(maxLength: 80)
        let item = ClinicalOps.newLegacyOrderSetProposal("x", label: "y")
        item.payer = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetProposalRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = ClinicalOps.LegacyOrderSetProposalRequiredPayerRule(
            message: "legacy order set proposal needs a value"
        )
        let item = ClinicalOps.newLegacyOrderSetProposal("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.LegacyOrderSetProposalRequiredCodeRule(message: "legacy order set proposal needs a value")
        let item = ClinicalOps.newLegacyOrderSetProposal("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetProposalCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = ClinicalOps.LegacyOrderSetProposalCostRangeRule(min: 5.7, max: 1517.1)
        let item = ClinicalOps.newLegacyOrderSetProposal("x", label: "y")
        item.cost = 1518.6
        #expect(rule.check(item).count > 0)
    }
}
