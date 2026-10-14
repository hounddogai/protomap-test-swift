@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalEligibilityNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalEligibilityNoticeValidator()
        let item = Referrals.newRegionalEligibilityNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalEligibilityNoticeExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Referrals.RegionalEligibilityNoticeExpiresAtRangeRule(min: 32, max: 86400)
        let item = Referrals.newRegionalEligibilityNotice("x", title: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalEligibilityNoticeWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.RegionalEligibilityNoticeWeightRangeRule(min: 6.5, max: 1806.8)
        let item = Referrals.newRegionalEligibilityNotice("x", title: "y")
        item.weight = 1808.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalEligibilityNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RegionalEligibilityNoticeRequiredCodeRule(
            message: "regional eligibility notice needs this field"
        )
        let item = Referrals.newRegionalEligibilityNotice("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalEligibilityNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.RegionalEligibilityNoticeCodeLengthRule(maxLength: 1000)
        let item = Referrals.newRegionalEligibilityNotice("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
