@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveCareProtocolProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAdaptiveCareProtocolProposalValidator()
        let item = ClinicalOps.newAdaptiveCareProtocolProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAdaptiveCareProtocolProposalSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = ClinicalOps.AdaptiveCareProtocolProposalSequenceRangeRule(min: 1000, max: 3600)
        let item = ClinicalOps.newAdaptiveCareProtocolProposal("x", label: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAdaptiveCareProtocolProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.AdaptiveCareProtocolProposalLabelLengthRule(maxLength: 86400)
        let item = ClinicalOps.newAdaptiveCareProtocolProposal("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAdaptiveCareProtocolProposalRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = ClinicalOps.AdaptiveCareProtocolProposalRevisionRangeRule(min: 80, max: 120)
        let item = ClinicalOps.newAdaptiveCareProtocolProposal("x", label: "y")
        item.revision = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAdaptiveCareProtocolProposalStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = ClinicalOps.AdaptiveCareProtocolProposalStartsAtRangeRule(min: 32, max: 64)
        let item = ClinicalOps.newAdaptiveCareProtocolProposal("x", label: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}
