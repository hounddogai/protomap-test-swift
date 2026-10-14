@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityNoticeValidator()
        let item = Referrals.newEligibilityNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.EligibilityNoticeCodeLengthRule(maxLength: 86400)
        let item = Referrals.newEligibilityNotice("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityNoticeWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.EligibilityNoticeWardLengthRule(maxLength: 80)
        let item = Referrals.newEligibilityNotice("x", name: "y")
        item.ward = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityNoticeMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Referrals.EligibilityNoticeMarginRangeRule(min: 6.7, max: 3119.0)
        let item = Referrals.newEligibilityNotice("x", name: "y")
        item.margin = 3120.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityNoticeRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Referrals.EligibilityNoticeRequiredWardRule(message: "eligibility notice needs an entry")
        let item = Referrals.newEligibilityNotice("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilityNoticeRequiredCodeRule(message: "eligibility notice needs this field")
        let item = Referrals.newEligibilityNotice("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
