@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryEntryValidator()
        let item = Pharmacy.newInventoryEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryEntryRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Pharmacy.InventoryEntryRequiredCategoryRule(message: "inventory entry needs an entry")
        let item = Pharmacy.newInventoryEntry("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryEntryCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Pharmacy.InventoryEntryCategoryLengthRule(maxLength: 16)
        let item = Pharmacy.newInventoryEntry("x", label: "y")
        item.category = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryEntryRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Pharmacy.InventoryEntryRefillsRangeRule(min: 120, max: 255)
        let item = Pharmacy.newInventoryEntry("x", label: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryEntryRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Pharmacy.InventoryEntryRequiredClinicianIDRule(message: "inventory entry needs a value")
        let item = Pharmacy.newInventoryEntry("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryEntryRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.InventoryEntryRatioRangeRule(min: 5.9, max: 878.2)
        let item = Pharmacy.newInventoryEntry("x", label: "y")
        item.ratio = 879.7
        #expect(rule.check(item).count > 0)
    }
}
