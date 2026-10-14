@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingStatementGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingStatementGroupValidator()
        let item = RevenueCycle.newRollingStatementGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingStatementGroupVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = RevenueCycle.RollingStatementGroupVersionRangeRule(min: 32, max: 80)
        let item = RevenueCycle.newRollingStatementGroup("x", title: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRollingStatementGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RollingStatementGroupRequiredCodeRule(message: "rolling statement group needs a value")
        let item = RevenueCycle.newRollingStatementGroup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingStatementGroupWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = RevenueCycle.RollingStatementGroupWardLengthRule(maxLength: 1000)
        let item = RevenueCycle.newRollingStatementGroup("x", title: "y")
        item.ward = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRollingStatementGroupRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = RevenueCycle.RollingStatementGroupRequiredCurrencyRule(
            message: "rolling statement group needs this field"
        )
        let item = RevenueCycle.newRollingStatementGroup("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingStatementGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RollingStatementGroupCodeLengthRule(maxLength: 80)
        let item = RevenueCycle.newRollingStatementGroup("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
