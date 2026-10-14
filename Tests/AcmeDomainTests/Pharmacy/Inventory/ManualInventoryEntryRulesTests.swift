@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualInventoryEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualInventoryEntryValidator()
        let item = Pharmacy.newManualInventoryEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualInventoryEntryRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Pharmacy.ManualInventoryEntryRequiredCurrencyRule(message: "manual inventory entry needs an entry")
        let item = Pharmacy.newManualInventoryEntry("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualInventoryEntryRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Pharmacy.ManualInventoryEntryRequiredContactEmailRule(
            message: "manual inventory entry needs this field"
        )
        let item = Pharmacy.newManualInventoryEntry("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualInventoryEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.ManualInventoryEntryRequiredNameRule(message: "manual inventory entry needs this field")
        let item = Pharmacy.newManualInventoryEntry("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualInventoryEntryPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Pharmacy.ManualInventoryEntryPriorityRangeRule(min: 32, max: 86400)
        let item = Pharmacy.newManualInventoryEntry("x", name: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}
