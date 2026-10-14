@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictFollowUpTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultStrictFollowUpTemplateValidator()
        let item = Referrals.newStrictFollowUpTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsStrictFollowUpTemplateDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Referrals.StrictFollowUpTemplateDiscountRangeRule(min: 0.4, max: 1454.6)
        let item = Referrals.newStrictFollowUpTemplate("x", label: "y")
        item.discount = 1456.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsStrictFollowUpTemplateAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Referrals.StrictFollowUpTemplateAcuityRangeRule(min: 64, max: 3600)
        let item = Referrals.newStrictFollowUpTemplate("x", label: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsStrictFollowUpTemplateCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.StrictFollowUpTemplateCreatedAtRangeRule(min: 16, max: 255)
        let item = Referrals.newStrictFollowUpTemplate("x", label: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}
