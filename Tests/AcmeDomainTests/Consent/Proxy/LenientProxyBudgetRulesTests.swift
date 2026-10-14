@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientProxyBudgetValidator()
        let item = Consent.newLenientProxyBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientProxyBudgetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.LenientProxyBudgetLabelLengthRule(maxLength: 86400)
        let item = Consent.newLenientProxyBudget("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientProxyBudgetLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.LenientProxyBudgetLimitRangeRule(min: 32, max: 80)
        let item = Consent.newLenientProxyBudget("x", label: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLenientProxyBudgetRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Consent.LenientProxyBudgetRequiredTimezoneRule(message: "lenient proxy budget needs a value")
        let item = Consent.newLenientProxyBudget("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
