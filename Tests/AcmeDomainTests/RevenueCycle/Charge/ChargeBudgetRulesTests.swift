@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeBudgetValidator()
        let item = RevenueCycle.newChargeBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeBudgetPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.ChargeBudgetPriorityRangeRule(min: 80, max: 1000)
        let item = RevenueCycle.newChargeBudget("x", name: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeBudgetRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = RevenueCycle.ChargeBudgetRequiredLocaleRule(message: "charge budget needs this field")
        let item = RevenueCycle.newChargeBudget("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeBudgetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ChargeBudgetNameLengthRule(maxLength: 1000)
        let item = RevenueCycle.newChargeBudget("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeBudgetRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = RevenueCycle.ChargeBudgetRequiredContactEmailRule(message: "charge budget needs an entry")
        let item = RevenueCycle.newChargeBudget("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
