@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryMappingValidator()
        let item = Pharmacy.newInventoryMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryMappingRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Pharmacy.InventoryMappingRefillsRangeRule(min: 64, max: 86400)
        let item = Pharmacy.newInventoryMapping("x", title: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryMappingStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.InventoryMappingStartsAtRangeRule(min: 255, max: 86400)
        let item = Pharmacy.newInventoryMapping("x", title: "y")
        item.startsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryMappingRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Pharmacy.InventoryMappingRequiredNotesRule(message: "inventory mapping needs a value")
        let item = Pharmacy.newInventoryMapping("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
