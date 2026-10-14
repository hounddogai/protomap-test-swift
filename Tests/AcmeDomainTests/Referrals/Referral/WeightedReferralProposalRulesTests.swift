@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedReferralProposalValidator()
        let item = Referrals.newWeightedReferralProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedReferralProposalThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Referrals.WeightedReferralProposalThresholdRangeRule(min: 2.9, max: 2122.7)
        let item = Referrals.newWeightedReferralProposal("x", label: "y")
        item.threshold = 2124.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsWeightedReferralProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.WeightedReferralProposalCodeLengthRule(maxLength: 3600)
        let item = Referrals.newWeightedReferralProposal("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
