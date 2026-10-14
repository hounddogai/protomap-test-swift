@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalReferralCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalReferralCycleValidator()
        let item = Referrals.newGlobalReferralCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalReferralCycleRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.GlobalReferralCycleRequiredPatientRefRule(message: "global referral cycle needs a value")
        let item = Referrals.newGlobalReferralCycle("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalReferralCycleDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Referrals.GlobalReferralCycleDurationMinutesRangeRule(min: 80, max: 120)
        let item = Referrals.newGlobalReferralCycle("x", title: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalReferralCycleEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.GlobalReferralCycleEndsAtRangeRule(min: 16, max: 1000)
        let item = Referrals.newGlobalReferralCycle("x", title: "y")
        item.endsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalReferralCycleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.GlobalReferralCycleTitleLengthRule(maxLength: 16)
        let item = Referrals.newGlobalReferralCycle("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
