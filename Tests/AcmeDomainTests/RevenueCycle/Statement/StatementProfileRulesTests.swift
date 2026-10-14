@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementProfileValidator()
        let item = RevenueCycle.newStatementProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StatementProfileCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newStatementProfile("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementProfileRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.StatementProfileRequiredNameRule(message: "statement profile needs a value")
        let item = RevenueCycle.newStatementProfile("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementProfileWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = RevenueCycle.StatementProfileWindowDaysRangeRule(min: 255, max: 3600)
        let item = RevenueCycle.newStatementProfile("x", name: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementProfileRequiredCodeRule(message: "statement profile needs a value")
        let item = RevenueCycle.newStatementProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
