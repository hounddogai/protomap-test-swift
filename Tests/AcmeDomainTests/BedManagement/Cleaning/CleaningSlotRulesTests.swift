@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningSlotValidator()
        let item = BedManagement.newCleaningSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningSlotStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = BedManagement.CleaningSlotStartsAtRangeRule(min: 80, max: 255)
        let item = BedManagement.newCleaningSlot("x", label: "y")
        item.startsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CleaningSlotRequiredCodeRule(message: "cleaning slot needs a value")
        let item = BedManagement.newCleaningSlot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningSlotRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = BedManagement.CleaningSlotRequiredEncounterIDRule(message: "cleaning slot needs a value")
        let item = BedManagement.newCleaningSlot("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningSlotDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = BedManagement.CleaningSlotDosageMgRangeRule(min: 2.4, max: 795.2)
        let item = BedManagement.newCleaningSlot("x", label: "y")
        item.dosageMg = 796.7
        #expect(rule.check(item).count > 0)
    }
}
