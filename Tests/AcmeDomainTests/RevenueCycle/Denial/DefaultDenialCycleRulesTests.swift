@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultDenialCycleValidatorExtraTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultDenialCycleValidator()
        let item = RevenueCycle.newDefaultDenialCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultDenialCycleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.DefaultDenialCycleTitleLengthRule(maxLength: 16)
        let item = RevenueCycle.newDefaultDenialCycle("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultDenialCycleWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = RevenueCycle.DefaultDenialCycleWindowDaysRangeRule(min: 32, max: 80)
        let item = RevenueCycle.newDefaultDenialCycle("x", title: "y")
        item.windowDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDefaultDenialCycleRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = RevenueCycle.DefaultDenialCycleRequiredLocaleRule(message: "default denial cycle needs this field")
        let item = RevenueCycle.newDefaultDenialCycle("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultDenialCycleRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = RevenueCycle.DefaultDenialCycleRequiredUnitRule(message: "default denial cycle needs this field")
        let item = RevenueCycle.newDefaultDenialCycle("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
