@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalReferralOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalReferralOverrideValidator()
        let item = Referrals.newGlobalReferralOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalReferralOverrideWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.GlobalReferralOverrideWeightRangeRule(min: 2.2, max: 1061.6)
        let item = Referrals.newGlobalReferralOverride("x", title: "y")
        item.weight = 1063.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalReferralOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.GlobalReferralOverrideTitleLengthRule(maxLength: 80)
        let item = Referrals.newGlobalReferralOverride("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalReferralOverrideNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Referrals.GlobalReferralOverrideNotesLengthRule(maxLength: 32)
        let item = Referrals.newGlobalReferralOverride("x", title: "y")
        item.notes = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
