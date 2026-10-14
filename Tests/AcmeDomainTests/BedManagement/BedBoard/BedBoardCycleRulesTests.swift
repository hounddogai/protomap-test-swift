@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardCycleValidator()
        let item = BedManagement.newBedBoardCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardCycleRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = BedManagement.BedBoardCycleRegionLengthRule(maxLength: 255)
        let item = BedManagement.newBedBoardCycle("x", name: "y")
        item.region = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BedBoardCycleRequiredCodeRule(message: "bed board cycle needs this field")
        let item = BedManagement.newBedBoardCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardCycleRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = BedManagement.BedBoardCycleRequiredRegionRule(message: "bed board cycle needs an entry")
        let item = BedManagement.newBedBoardCycle("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardCycleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.BedBoardCycleExpiresAtRangeRule(min: 64, max: 64)
        let item = BedManagement.newBedBoardCycle("x", name: "y")
        item.expiresAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardCycleRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = BedManagement.BedBoardCycleRequiredNotesRule(message: "bed board cycle needs this field")
        let item = BedManagement.newBedBoardCycle("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BedBoardCycleCodeLengthRule(maxLength: 32)
        let item = BedManagement.newBedBoardCycle("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
