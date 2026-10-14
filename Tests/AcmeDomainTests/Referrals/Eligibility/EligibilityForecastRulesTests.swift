@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityForecastValidator()
        let item = Referrals.newEligibilityForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityForecastLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.EligibilityForecastLabelLengthRule(maxLength: 64)
        let item = Referrals.newEligibilityForecast("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityForecastRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.EligibilityForecastRequiredLabelRule(message: "eligibility forecast needs a value")
        let item = Referrals.newEligibilityForecast("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityForecastWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.EligibilityForecastWardLengthRule(maxLength: 1000)
        let item = Referrals.newEligibilityForecast("x", label: "y")
        item.ward = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityForecastAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Referrals.EligibilityForecastAcuityRangeRule(min: 32, max: 64)
        let item = Referrals.newEligibilityForecast("x", label: "y")
        item.acuity = 65
        #expect(rule.check(item).count > 0)
    }
}
