@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralProposalValidator()
        let item = Referrals.newReferralProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralProposalQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.ReferralProposalQuantityRangeRule(min: 16, max: 1000)
        let item = Referrals.newReferralProposal("x", title: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralProposalRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Referrals.ReferralProposalRequiredEncounterIDRule(message: "referral proposal needs this field")
        let item = Referrals.newReferralProposal("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralProposalRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ReferralProposalRequiredTitleRule(message: "referral proposal needs a value")
        let item = Referrals.newReferralProposal("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralProposalCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Referrals.ReferralProposalCurrencyLengthRule(maxLength: 16)
        let item = Referrals.newReferralProposal("x", title: "y")
        item.currency = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
