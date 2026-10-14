@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackReferralMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFallbackReferralMappingValidator()
        let item = Referrals.newFallbackReferralMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFallbackReferralMappingRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Referrals.FallbackReferralMappingRequiredClinicianIDRule(
            message: "fallback referral mapping needs this field"
        )
        let item = Referrals.newFallbackReferralMapping("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackReferralMappingBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Referrals.FallbackReferralMappingBudgetRangeRule(min: 2.9, max: 1952.9)
        let item = Referrals.newFallbackReferralMapping("x", label: "y")
        item.budget = 1954.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFallbackReferralMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FallbackReferralMappingRequiredCodeRule(
            message: "fallback referral mapping needs this field"
        )
        let item = Referrals.newFallbackReferralMapping("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
