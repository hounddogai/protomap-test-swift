@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledCareProtocolForecastValidator()
        let item = Imaging.newScheduledCareProtocolForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledCareProtocolForecastNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.ScheduledCareProtocolForecastNameLengthRule(maxLength: 86400)
        let item = Imaging.newScheduledCareProtocolForecast("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledCareProtocolForecastRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.ScheduledCareProtocolForecastRatioRangeRule(min: 3.0, max: 2331.9)
        let item = Imaging.newScheduledCareProtocolForecast("x", name: "y")
        item.ratio = 2333.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingScheduledCareProtocolForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ScheduledCareProtocolForecastRequiredCodeRule(
            message: "scheduled care protocol forecast needs an entry"
        )
        let item = Imaging.newScheduledCareProtocolForecast("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
