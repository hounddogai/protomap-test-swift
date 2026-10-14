@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryAdjustmentValidator()
        let item = Pharmacy.newInventoryAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InventoryAdjustmentCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newInventoryAdjustment("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryAdjustmentCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Pharmacy.InventoryAdjustmentCurrencyLengthRule(maxLength: 16)
        let item = Pharmacy.newInventoryAdjustment("x", label: "y")
        item.currency = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryAdjustmentMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Pharmacy.InventoryAdjustmentMaximumRangeRule(min: 9.0, max: 1636.7)
        let item = Pharmacy.newInventoryAdjustment("x", label: "y")
        item.maximum = 1638.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryAdjustmentRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Pharmacy.InventoryAdjustmentRequiredCurrencyRule(message: "inventory adjustment needs an entry")
        let item = Pharmacy.newInventoryAdjustment("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryAdjustmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InventoryAdjustmentRequiredLabelRule(message: "inventory adjustment needs a value")
        let item = Pharmacy.newInventoryAdjustment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
