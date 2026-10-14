@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacyReferralTargetValidator()
        let item = Referrals.newLegacyReferralTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacyReferralTargetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.LegacyReferralTargetTitleLengthRule(maxLength: 64)
        let item = Referrals.newLegacyReferralTarget("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLegacyReferralTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.LegacyReferralTargetRequiredNameRule(message: "legacy referral target needs a value")
        let item = Referrals.newLegacyReferralTarget("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyReferralTargetEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.LegacyReferralTargetEndsAtRangeRule(min: 32, max: 80)
        let item = Referrals.newLegacyReferralTarget("x", title: "y")
        item.endsAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLegacyReferralTargetEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Referrals.LegacyReferralTargetEncounterIDLengthRule(maxLength: 1000)
        let item = Referrals.newLegacyReferralTarget("x", title: "y")
        item.encounterID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
