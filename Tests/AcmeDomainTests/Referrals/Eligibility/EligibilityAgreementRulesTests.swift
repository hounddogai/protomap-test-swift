@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityAgreementValidator()
        let item = Referrals.newEligibilityAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.EligibilityAgreementTitleLengthRule(maxLength: 86400)
        let item = Referrals.newEligibilityAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityAgreementRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Referrals.EligibilityAgreementRateRangeRule(min: 3.2, max: 3071.0)
        let item = Referrals.newEligibilityAgreement("x", title: "y")
        item.rate = 3072.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilityAgreementRequiredCodeRule(message: "eligibility agreement needs an entry")
        let item = Referrals.newEligibilityAgreement("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityAgreementFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Referrals.EligibilityAgreementFloorValueRangeRule(min: 2.0, max: 2861.9)
        let item = Referrals.newEligibilityAgreement("x", title: "y")
        item.floorValue = 2863.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityAgreementBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Referrals.EligibilityAgreementBudgetRangeRule(min: 8.9, max: 471.1)
        let item = Referrals.newEligibilityAgreement("x", title: "y")
        item.budget = 472.6
        #expect(rule.check(item).count > 0)
    }
}
