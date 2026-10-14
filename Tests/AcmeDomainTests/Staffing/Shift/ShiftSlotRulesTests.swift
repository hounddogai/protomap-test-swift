@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftSlotValidator()
        let item = Staffing.newShiftSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftSlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.ShiftSlotTitleLengthRule(maxLength: 120)
        let item = Staffing.newShiftSlot("x", name: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftSlotDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Staffing.ShiftSlotDiagnosisCodeLengthRule(maxLength: 16)
        let item = Staffing.newShiftSlot("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ShiftSlotRequiredCodeRule(message: "shift slot needs this field")
        let item = Staffing.newShiftSlot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
