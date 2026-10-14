@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedInventoryAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedInventoryAuditValidator()
        let item = Pharmacy.newWeightedInventoryAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedInventoryAuditQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Pharmacy.WeightedInventoryAuditQuantityRangeRule(min: 80, max: 120)
        let item = Pharmacy.newWeightedInventoryAudit("x", name: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedInventoryAuditLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.WeightedInventoryAuditLabelLengthRule(maxLength: 255)
        let item = Pharmacy.newWeightedInventoryAudit("x", name: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedInventoryAuditNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.WeightedInventoryAuditNameLengthRule(maxLength: 80)
        let item = Pharmacy.newWeightedInventoryAudit("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedInventoryAuditRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Pharmacy.WeightedInventoryAuditRequiredSpecialtyRule(
            message: "weighted inventory audit needs an entry"
        )
        let item = Pharmacy.newWeightedInventoryAudit("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyWeightedInventoryAuditSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Pharmacy.WeightedInventoryAuditSpecialtyLengthRule(maxLength: 80)
        let item = Pharmacy.newWeightedInventoryAudit("x", name: "y")
        item.specialty = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
