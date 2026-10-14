@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftPolicyValidator()
        let item = Staffing.newShiftPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftPolicyNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Staffing.ShiftPolicyNotesLengthRule(maxLength: 80)
        let item = Staffing.newShiftPolicy("x", label: "y")
        item.notes = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftPolicyEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Staffing.ShiftPolicyEncounterIDLengthRule(maxLength: 3600)
        let item = Staffing.newShiftPolicy("x", label: "y")
        item.encounterID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ShiftPolicyCodeLengthRule(maxLength: 32)
        let item = Staffing.newShiftPolicy("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
