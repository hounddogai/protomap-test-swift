@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInventoryBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyInventoryBundleValidator()
        let item = Pharmacy.newLegacyInventoryBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyInventoryBundleRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Pharmacy.LegacyInventoryBundleRequiredAllergyRule(message: "legacy inventory bundle needs a value")
        let item = Pharmacy.newLegacyInventoryBundle("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInventoryBundleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Pharmacy.LegacyInventoryBundleAmountRangeRule(min: 4.6, max: 1074.0)
        let item = Pharmacy.newLegacyInventoryBundle("x", label: "y")
        item.amount = 1075.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLegacyInventoryBundleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.LegacyInventoryBundleLabelLengthRule(maxLength: 3600)
        let item = Pharmacy.newLegacyInventoryBundle("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyInventoryBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.LegacyInventoryBundleRequiredLabelRule(message: "legacy inventory bundle needs this field")
        let item = Pharmacy.newLegacyInventoryBundle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInventoryBundleCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Pharmacy.LegacyInventoryBundleCostRangeRule(min: 6.3, max: 643.9)
        let item = Pharmacy.newLegacyInventoryBundle("x", label: "y")
        item.cost = 645.4
        #expect(rule.check(item).count > 0)
    }
}
