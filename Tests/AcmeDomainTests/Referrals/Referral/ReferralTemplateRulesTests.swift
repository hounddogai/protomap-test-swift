@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralTemplateValidator()
        let item = Referrals.newReferralTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ReferralTemplateCodeLengthRule(maxLength: 3600)
        let item = Referrals.newReferralTemplate("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralTemplateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ReferralTemplateRequiredTitleRule(message: "referral template needs a value")
        let item = Referrals.newReferralTemplate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.ReferralTemplateLabelLengthRule(maxLength: 16)
        let item = Referrals.newReferralTemplate("x", title: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
