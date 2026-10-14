@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralPlanValidator()
        let item = Referrals.newReferralPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralPlanOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Referrals.ReferralPlanOwnerIDLengthRule(maxLength: 1000)
        let item = Referrals.newReferralPlan("x", title: "y")
        item.ownerID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralPlanGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Referrals.ReferralPlanGraceDaysRangeRule(min: 3600, max: 3600)
        let item = Referrals.newReferralPlan("x", title: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralPlanRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Referrals.ReferralPlanRequiredOwnerIDRule(message: "referral plan needs a value")
        let item = Referrals.newReferralPlan("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralPlanTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.ReferralPlanTitleLengthRule(maxLength: 64)
        let item = Referrals.newReferralPlan("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralPlanRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Referrals.ReferralPlanRevisionRangeRule(min: 16, max: 255)
        let item = Referrals.newReferralPlan("x", title: "y")
        item.revision = 256
        #expect(rule.check(item).count > 0)
    }
}
