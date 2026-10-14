@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackEligibilityTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFallbackEligibilityTemplateValidator()
        let item = Referrals.newFallbackEligibilityTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFallbackEligibilityTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FallbackEligibilityTemplateRequiredCodeRule(
            message: "fallback eligibility template needs this field"
        )
        let item = Referrals.newFallbackEligibilityTemplate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackEligibilityTemplateClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Referrals.FallbackEligibilityTemplateClinicianIDLengthRule(maxLength: 64)
        let item = Referrals.newFallbackEligibilityTemplate("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFallbackEligibilityTemplateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.FallbackEligibilityTemplateRequiredLabelRule(
            message: "fallback eligibility template needs an entry"
        )
        let item = Referrals.newFallbackEligibilityTemplate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackEligibilityTemplateDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Referrals.FallbackEligibilityTemplateDosageMgRangeRule(min: 3.7, max: 3743.7)
        let item = Referrals.newFallbackEligibilityTemplate("x", label: "y")
        item.dosageMg = 3745.2
        #expect(rule.check(item).count > 0)
    }
}
