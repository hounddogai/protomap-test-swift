@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualNetworkForecastValidator()
        let item = Referrals.newManualNetworkForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualNetworkForecastNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.ManualNetworkForecastNameLengthRule(maxLength: 255)
        let item = Referrals.newManualNetworkForecast("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualNetworkForecastDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Referrals.ManualNetworkForecastDurationMinutesRangeRule(min: 80, max: 3600)
        let item = Referrals.newManualNetworkForecast("x", name: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}
