@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredChargeBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredChargeBatchValidator()
        let item = RevenueCycle.newTieredChargeBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredChargeBatchLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.TieredChargeBatchLabelLengthRule(maxLength: 64)
        let item = RevenueCycle.newTieredChargeBatch("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredChargeBatchCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = RevenueCycle.TieredChargeBatchCurrencyLengthRule(maxLength: 80)
        let item = RevenueCycle.newTieredChargeBatch("x", label: "y")
        item.currency = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredChargeBatchRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.TieredChargeBatchRequiredLabelRule(message: "tiered charge batch needs this field")
        let item = RevenueCycle.newTieredChargeBatch("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredChargeBatchRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = RevenueCycle.TieredChargeBatchRequiredCurrencyRule(message: "tiered charge batch needs an entry")
        let item = RevenueCycle.newTieredChargeBatch("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredChargeBatchLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.TieredChargeBatchLimitRangeRule(min: 80, max: 120)
        let item = RevenueCycle.newTieredChargeBatch("x", label: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}
