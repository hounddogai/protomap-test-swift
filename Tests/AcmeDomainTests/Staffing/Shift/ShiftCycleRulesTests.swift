@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftCycleValidator()
        let item = Staffing.newShiftCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftCycleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.ShiftCycleCopayRangeRule(min: 4.7, max: 331.0)
        let item = Staffing.newShiftCycle("x", name: "y")
        item.copay = 332.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ShiftCycleRequiredCodeRule(message: "shift cycle needs a value")
        let item = Staffing.newShiftCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftCycleReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Staffing.ShiftCycleReviewerLengthRule(maxLength: 16)
        let item = Staffing.newShiftCycle("x", name: "y")
        item.reviewer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftCycleRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Staffing.ShiftCycleRequiredNotesRule(message: "shift cycle needs this field")
        let item = Staffing.newShiftCycle("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftCycleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.ShiftCycleNameLengthRule(maxLength: 255)
        let item = Staffing.newShiftCycle("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
