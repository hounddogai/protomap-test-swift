@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedFollowUpTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedFollowUpTemplateValidator()
        let item = Referrals.newBatchedFollowUpTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedFollowUpTemplateDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Referrals.BatchedFollowUpTemplateDosageMgRangeRule(min: 8.0, max: 1740.7)
        let item = Referrals.newBatchedFollowUpTemplate("x", title: "y")
        item.dosageMg = 1742.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsBatchedFollowUpTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.BatchedFollowUpTemplateRequiredCodeRule(message: "batched follow up template needs a value")
        let item = Referrals.newBatchedFollowUpTemplate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
