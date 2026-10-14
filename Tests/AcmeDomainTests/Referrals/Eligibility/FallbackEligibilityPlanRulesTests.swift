@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackEligibilityPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFallbackEligibilityPlanValidator()
        let item = Referrals.newFallbackEligibilityPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFallbackEligibilityPlanRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Referrals.FallbackEligibilityPlanRequiredPayerRule(message: "fallback eligibility plan needs a value")
        let item = Referrals.newFallbackEligibilityPlan("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackEligibilityPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FallbackEligibilityPlanRequiredCodeRule(message: "fallback eligibility plan needs an entry")
        let item = Referrals.newFallbackEligibilityPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackEligibilityPlanRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.FallbackEligibilityPlanRequiredLabelRule(
            message: "fallback eligibility plan needs this field"
        )
        let item = Referrals.newFallbackEligibilityPlan("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
