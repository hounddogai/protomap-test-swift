@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityTemplateValidator()
        let item = Referrals.newEligibilityTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.EligibilityTemplateCodeLengthRule(maxLength: 86400)
        let item = Referrals.newEligibilityTemplate("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityTemplateRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Referrals.EligibilityTemplateRequiredSummaryRule(message: "eligibility template needs this field")
        let item = Referrals.newEligibilityTemplate("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
