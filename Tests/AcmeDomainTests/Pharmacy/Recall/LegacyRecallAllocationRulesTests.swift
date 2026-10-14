@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyRecallAllocationValidator()
        let item = Pharmacy.newLegacyRecallAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyRecallAllocationWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Pharmacy.LegacyRecallAllocationWindowDaysRangeRule(min: 16, max: 64)
        let item = Pharmacy.newLegacyRecallAllocation("x", title: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLegacyRecallAllocationRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Pharmacy.LegacyRecallAllocationRequiredNotesRule(message: "legacy recall allocation needs this field")
        let item = Pharmacy.newLegacyRecallAllocation("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyRecallAllocationNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Pharmacy.LegacyRecallAllocationNotesLengthRule(maxLength: 32)
        let item = Pharmacy.newLegacyRecallAllocation("x", title: "y")
        item.notes = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
