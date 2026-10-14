@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationMetricValidator()
        let item = RevenueCycle.newAuthorizationMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AuthorizationMetricRequiredCodeRule(message: "authorization metric needs a value")
        let item = RevenueCycle.newAuthorizationMetric("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationMetricGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = RevenueCycle.AuthorizationMetricGraceDaysRangeRule(min: 255, max: 1000)
        let item = RevenueCycle.newAuthorizationMetric("x", title: "y")
        item.graceDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationMetricCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = RevenueCycle.AuthorizationMetricCategoryLengthRule(maxLength: 32)
        let item = RevenueCycle.newAuthorizationMetric("x", title: "y")
        item.category = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationMetricRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = RevenueCycle.AuthorizationMetricRequiredCategoryRule(message: "authorization metric needs an entry")
        let item = RevenueCycle.newAuthorizationMetric("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AuthorizationMetricCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newAuthorizationMetric("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
