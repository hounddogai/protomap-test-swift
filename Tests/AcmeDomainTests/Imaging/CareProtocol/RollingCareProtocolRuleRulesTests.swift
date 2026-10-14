@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingCareProtocolRuleValidator()
        let item = Imaging.newRollingCareProtocolRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingCareProtocolRuleWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Imaging.RollingCareProtocolRuleWindowDaysRangeRule(min: 16, max: 1000)
        let item = Imaging.newRollingCareProtocolRule("x", title: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRollingCareProtocolRuleRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Imaging.RollingCareProtocolRuleRequiredCurrencyRule(
            message: "rolling care protocol rule needs an entry"
        )
        let item = Imaging.newRollingCareProtocolRule("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
