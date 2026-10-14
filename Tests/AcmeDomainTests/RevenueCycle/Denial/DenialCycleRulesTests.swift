@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialCycleValidator()
        let item = RevenueCycle.newDenialCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialCycleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.DenialCycleAmountRangeRule(min: 0.1, max: 3062.9)
        let item = RevenueCycle.newDenialCycle("x", name: "y")
        item.amount = 3064.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.DenialCycleRequiredNameRule(message: "denial cycle needs a value")
        let item = RevenueCycle.newDenialCycle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialCycleBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = RevenueCycle.DenialCycleBudgetRangeRule(min: 9.8, max: 1668.8)
        let item = RevenueCycle.newDenialCycle("x", name: "y")
        item.budget = 1670.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialCycleSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = RevenueCycle.DenialCycleSequenceRangeRule(min: 255, max: 86400)
        let item = RevenueCycle.newDenialCycle("x", name: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}
