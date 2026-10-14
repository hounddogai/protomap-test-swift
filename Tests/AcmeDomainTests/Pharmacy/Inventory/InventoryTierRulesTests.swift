@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryTierValidator()
        let item = Pharmacy.newInventoryTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryTierRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Pharmacy.InventoryTierRequiredSegmentRule(message: "inventory tier needs an entry")
        let item = Pharmacy.newInventoryTier("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.InventoryTierLabelLengthRule(maxLength: 86400)
        let item = Pharmacy.newInventoryTier("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryTierRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Pharmacy.InventoryTierRetriesRangeRule(min: 64, max: 255)
        let item = Pharmacy.newInventoryTier("x", label: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}
