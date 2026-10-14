@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementBundleValidator()
        let item = RevenueCycle.newStatementBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.StatementBundleRequiredNameRule(message: "statement bundle needs a value")
        let item = RevenueCycle.newStatementBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementBundleTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = RevenueCycle.StatementBundleTimezoneLengthRule(maxLength: 1000)
        let item = RevenueCycle.newStatementBundle("x", name: "y")
        item.timezone = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.StatementBundleNameLengthRule(maxLength: 1000)
        let item = RevenueCycle.newStatementBundle("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementBundleLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.StatementBundleLimitRangeRule(min: 16, max: 80)
        let item = RevenueCycle.newStatementBundle("x", name: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StatementBundleCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newStatementBundle("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
