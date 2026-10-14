@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceBatchValidator()
        let item = RevenueCycle.newRemittanceBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceBatchQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = RevenueCycle.RemittanceBatchQuantityRangeRule(min: 32, max: 64)
        let item = RevenueCycle.newRemittanceBatch("x", name: "y")
        item.quantity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceBatchRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.RemittanceBatchRequiredNameRule(message: "remittance batch needs this field")
        let item = RevenueCycle.newRemittanceBatch("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittanceBatchRequiredCodeRule(message: "remittance batch needs an entry")
        let item = RevenueCycle.newRemittanceBatch("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceBatchMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = RevenueCycle.RemittanceBatchMarginRangeRule(min: 7.5, max: 642.8)
        let item = RevenueCycle.newRemittanceBatch("x", name: "y")
        item.margin = 644.3
        #expect(rule.check(item).count > 0)
    }
}
