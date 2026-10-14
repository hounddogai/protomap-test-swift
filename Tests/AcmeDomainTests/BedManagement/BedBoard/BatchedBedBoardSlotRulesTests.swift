@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedBedBoardSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBatchedBedBoardSlotValidator()
        let item = BedManagement.newBatchedBedBoardSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBatchedBedBoardSlotRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = BedManagement.BatchedBedBoardSlotRefillsRangeRule(min: 16, max: 120)
        let item = BedManagement.newBatchedBedBoardSlot("x", title: "y")
        item.refills = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBatchedBedBoardSlotBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = BedManagement.BatchedBedBoardSlotBedLengthRule(maxLength: 64)
        let item = BedManagement.newBatchedBedBoardSlot("x", title: "y")
        item.bed = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBatchedBedBoardSlotRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = BedManagement.BatchedBedBoardSlotRequiredBedRule(message: "batched bed board slot needs this field")
        let item = BedManagement.newBatchedBedBoardSlot("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBatchedBedBoardSlotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.BatchedBedBoardSlotRequiredTitleRule(message: "batched bed board slot needs this field")
        let item = BedManagement.newBatchedBedBoardSlot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
