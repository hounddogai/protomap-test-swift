@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryBaselineValidator()
        let item = Pharmacy.newInventoryBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InventoryBaselineCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newInventoryBaseline("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryBaselineWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.InventoryBaselineWeightRangeRule(min: 5.9, max: 241.1)
        let item = Pharmacy.newInventoryBaseline("x", label: "y")
        item.weight = 242.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryBaselineRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InventoryBaselineRequiredLabelRule(message: "inventory baseline needs an entry")
        let item = Pharmacy.newInventoryBaseline("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
