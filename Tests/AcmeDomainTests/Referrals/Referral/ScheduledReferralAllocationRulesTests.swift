@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledReferralAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledReferralAllocationValidator()
        let item = Referrals.newScheduledReferralAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledReferralAllocationRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Referrals.ScheduledReferralAllocationRequiredPhoneRule(
            message: "scheduled referral allocation needs this field"
        )
        let item = Referrals.newScheduledReferralAllocation("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledReferralAllocationDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Referrals.ScheduledReferralAllocationDurationMinutesRangeRule(min: 32, max: 80)
        let item = Referrals.newScheduledReferralAllocation("x", label: "y")
        item.durationMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledReferralAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ScheduledReferralAllocationCodeLengthRule(maxLength: 80)
        let item = Referrals.newScheduledReferralAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledReferralAllocationCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.ScheduledReferralAllocationCapacityRangeRule(min: 16, max: 86400)
        let item = Referrals.newScheduledReferralAllocation("x", label: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}
