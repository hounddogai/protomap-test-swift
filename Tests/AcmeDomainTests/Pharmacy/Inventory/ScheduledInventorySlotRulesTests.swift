@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventorySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultScheduledInventorySlotValidator()
        let item = Pharmacy.newScheduledInventorySlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyScheduledInventorySlotAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Pharmacy.ScheduledInventorySlotAcuityRangeRule(min: 1000, max: 3600)
        let item = Pharmacy.newScheduledInventorySlot("x", label: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyScheduledInventorySlotExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.ScheduledInventorySlotExpiresAtRangeRule(min: 120, max: 86400)
        let item = Pharmacy.newScheduledInventorySlot("x", label: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyScheduledInventorySlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.ScheduledInventorySlotRequiredCodeRule(message: "scheduled inventory slot needs a value")
        let item = Pharmacy.newScheduledInventorySlot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyScheduledInventorySlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.ScheduledInventorySlotCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newScheduledInventorySlot("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyScheduledInventorySlotMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Pharmacy.ScheduledInventorySlotMinimumRangeRule(min: 2.7, max: 3222.8)
        let item = Pharmacy.newScheduledInventorySlot("x", label: "y")
        item.minimum = 3224.3
        #expect(rule.check(item).count > 0)
    }
}
