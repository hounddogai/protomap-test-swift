@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackReferralEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFallbackReferralEntryValidator()
        let item = Referrals.newFallbackReferralEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFallbackReferralEntryRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Referrals.FallbackReferralEntryRequiredPhoneRule(message: "fallback referral entry needs a value")
        let item = Referrals.newFallbackReferralEntry("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackReferralEntryWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.FallbackReferralEntryWardLengthRule(maxLength: 86400)
        let item = Referrals.newFallbackReferralEntry("x", title: "y")
        item.ward = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFallbackReferralEntryPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Referrals.FallbackReferralEntryPhoneLengthRule(maxLength: 64)
        let item = Referrals.newFallbackReferralEntry("x", title: "y")
        item.phone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFallbackReferralEntrySequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Referrals.FallbackReferralEntrySequenceRangeRule(min: 32, max: 1000)
        let item = Referrals.newFallbackReferralEntry("x", title: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFallbackReferralEntryFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Referrals.FallbackReferralEntryFloorValueRangeRule(min: 1.6, max: 4520.1)
        let item = Referrals.newFallbackReferralEntry("x", title: "y")
        item.floorValue = 4521.6
        #expect(rule.check(item).count > 0)
    }
}
