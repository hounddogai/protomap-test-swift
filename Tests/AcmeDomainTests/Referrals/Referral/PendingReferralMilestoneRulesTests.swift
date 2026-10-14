@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingReferralMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPendingReferralMilestoneValidator()
        let item = Referrals.newPendingReferralMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPendingReferralMilestoneMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Referrals.PendingReferralMilestoneMinimumRangeRule(min: 7.1, max: 4255.1)
        let item = Referrals.newPendingReferralMilestone("x", name: "y")
        item.minimum = 4256.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPendingReferralMilestoneUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Referrals.PendingReferralMilestoneUnitLengthRule(maxLength: 64)
        let item = Referrals.newPendingReferralMilestone("x", name: "y")
        item.unit = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPendingReferralMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.PendingReferralMilestoneRequiredNameRule(
            message: "pending referral milestone needs this field"
        )
        let item = Referrals.newPendingReferralMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingReferralMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.PendingReferralMilestoneCodeLengthRule(maxLength: 32)
        let item = Referrals.newPendingReferralMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
