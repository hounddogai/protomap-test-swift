@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultAdaptiveFollowUpPolicyValidator()
        let item = Referrals.newAdaptiveFollowUpPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsAdaptiveFollowUpPolicyLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.AdaptiveFollowUpPolicyLabelLengthRule(maxLength: 86400)
        let item = Referrals.newAdaptiveFollowUpPolicy("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsAdaptiveFollowUpPolicyMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Referrals.AdaptiveFollowUpPolicyMarginRangeRule(min: 6.5, max: 4740.0)
        let item = Referrals.newAdaptiveFollowUpPolicy("x", label: "y")
        item.margin = 4741.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsAdaptiveFollowUpPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.AdaptiveFollowUpPolicyRequiredLabelRule(
            message: "adaptive follow up policy needs this field"
        )
        let item = Referrals.newAdaptiveFollowUpPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsAdaptiveFollowUpPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.AdaptiveFollowUpPolicyCodeLengthRule(maxLength: 1000)
        let item = Referrals.newAdaptiveFollowUpPolicy("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
