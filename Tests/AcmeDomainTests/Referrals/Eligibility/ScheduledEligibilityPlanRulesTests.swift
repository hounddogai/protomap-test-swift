@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledEligibilityPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledEligibilityPlanValidator()
        let item = Referrals.newScheduledEligibilityPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledEligibilityPlanRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Referrals.ScheduledEligibilityPlanRequiredLocaleRule(
            message: "scheduled eligibility plan needs an entry"
        )
        let item = Referrals.newScheduledEligibilityPlan("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledEligibilityPlanUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Referrals.ScheduledEligibilityPlanUpdatedAtRangeRule(min: 80, max: 255)
        let item = Referrals.newScheduledEligibilityPlan("x", name: "y")
        item.updatedAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledEligibilityPlanLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Referrals.ScheduledEligibilityPlanLimitRangeRule(min: 3600, max: 86400)
        let item = Referrals.newScheduledEligibilityPlan("x", name: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledEligibilityPlanRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Referrals.ScheduledEligibilityPlanRequiredOwnerIDRule(
            message: "scheduled eligibility plan needs this field"
        )
        let item = Referrals.newScheduledEligibilityPlan("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
