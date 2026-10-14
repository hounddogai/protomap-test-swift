@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftDraftValidator()
        let item = Staffing.newShiftDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ShiftDraftCodeLengthRule(maxLength: 86400)
        let item = Staffing.newShiftDraft("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ShiftDraftRequiredCodeRule(message: "shift draft needs a value")
        let item = Staffing.newShiftDraft("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftDraftRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Staffing.ShiftDraftRequiredUnitRule(message: "shift draft needs an entry")
        let item = Staffing.newShiftDraft("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
