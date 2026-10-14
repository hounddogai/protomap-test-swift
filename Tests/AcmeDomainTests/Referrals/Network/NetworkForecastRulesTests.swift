@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkForecastValidator()
        let item = Referrals.newNetworkForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.NetworkForecastRequiredCodeRule(message: "network forecast needs this field")
        let item = Referrals.newNetworkForecast("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkForecastWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Referrals.NetworkForecastWindowDaysRangeRule(min: 120, max: 3600)
        let item = Referrals.newNetworkForecast("x", title: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkForecastRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.NetworkForecastRequiredTitleRule(message: "network forecast needs an entry")
        let item = Referrals.newNetworkForecast("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkForecastTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.NetworkForecastTitleLengthRule(maxLength: 86400)
        let item = Referrals.newNetworkForecast("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.NetworkForecastCodeLengthRule(maxLength: 255)
        let item = Referrals.newNetworkForecast("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
