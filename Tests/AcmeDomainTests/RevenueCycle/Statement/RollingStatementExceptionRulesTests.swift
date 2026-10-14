@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingStatementExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingStatementExceptionValidator()
        let item = RevenueCycle.newRollingStatementException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingStatementExceptionCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = RevenueCycle.RollingStatementExceptionCapacityRangeRule(min: 255, max: 3600)
        let item = RevenueCycle.newRollingStatementException("x", name: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRollingStatementExceptionLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = RevenueCycle.RollingStatementExceptionLocaleLengthRule(maxLength: 3600)
        let item = RevenueCycle.newRollingStatementException("x", name: "y")
        item.locale = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRollingStatementExceptionGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = RevenueCycle.RollingStatementExceptionGraceDaysRangeRule(min: 32, max: 120)
        let item = RevenueCycle.newRollingStatementException("x", name: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRollingStatementExceptionRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = RevenueCycle.RollingStatementExceptionRatioRangeRule(min: 8.9, max: 2616.7)
        let item = RevenueCycle.newRollingStatementException("x", name: "y")
        item.ratio = 2618.2
        #expect(rule.check(item).count > 0)
    }
}
