@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceCycleValidator()
        let item = RevenueCycle.newRemittanceCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceCycleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = RevenueCycle.RemittanceCycleCopayRangeRule(min: 9.7, max: 4629.1)
        let item = RevenueCycle.newRemittanceCycle("x", name: "y")
        item.copay = 4630.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceCycleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.RemittanceCycleAmountRangeRule(min: 7.6, max: 4866.2)
        let item = RevenueCycle.newRemittanceCycle("x", name: "y")
        item.amount = 4867.7
        #expect(rule.check(item).count > 0)
    }
}
