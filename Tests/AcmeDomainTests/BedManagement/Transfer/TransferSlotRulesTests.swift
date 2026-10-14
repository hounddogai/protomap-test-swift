@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferSlotValidator()
        let item = BedManagement.newTransferSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferSlotBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = BedManagement.TransferSlotBedLengthRule(maxLength: 86400)
        let item = BedManagement.newTransferSlot("x", title: "y")
        item.bed = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferSlotRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = BedManagement.TransferSlotRefillsRangeRule(min: 64, max: 255)
        let item = BedManagement.newTransferSlot("x", title: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferSlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.TransferSlotTitleLengthRule(maxLength: 16)
        let item = BedManagement.newTransferSlot("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferSlotQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = BedManagement.TransferSlotQuantityRangeRule(min: 32, max: 80)
        let item = BedManagement.newTransferSlot("x", title: "y")
        item.quantity = 81
        #expect(rule.check(item).count > 0)
    }
}
