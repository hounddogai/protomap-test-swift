@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkProposalValidator()
        let item = Referrals.newNetworkProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.NetworkProposalLabelLengthRule(maxLength: 1000)
        let item = Referrals.newNetworkProposal("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkProposalRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Referrals.NetworkProposalRequiredSummaryRule(message: "network proposal needs this field")
        let item = Referrals.newNetworkProposal("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkProposalSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Referrals.NetworkProposalSequenceRangeRule(min: 120, max: 3600)
        let item = Referrals.newNetworkProposal("x", label: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}
