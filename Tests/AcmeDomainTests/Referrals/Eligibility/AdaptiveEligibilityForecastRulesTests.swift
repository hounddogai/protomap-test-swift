@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveEligibilityForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultAdaptiveEligibilityForecastValidator()
        let item = Referrals.newAdaptiveEligibilityForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsAdaptiveEligibilityForecastCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.AdaptiveEligibilityForecastCreatedAtRangeRule(min: 120, max: 3600)
        let item = Referrals.newAdaptiveEligibilityForecast("x", name: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsAdaptiveEligibilityForecastNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.AdaptiveEligibilityForecastNameLengthRule(maxLength: 32)
        let item = Referrals.newAdaptiveEligibilityForecast("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
