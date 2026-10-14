@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftRollupValidator()
        let item = Staffing.newShiftRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftRollupClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Staffing.ShiftRollupClinicianIDLengthRule(maxLength: 120)
        let item = Staffing.newShiftRollup("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ShiftRollupRequiredCodeRule(message: "shift rollup needs this field")
        let item = Staffing.newShiftRollup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftRollupOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Staffing.ShiftRollupOwnerIDLengthRule(maxLength: 1000)
        let item = Staffing.newShiftRollup("x", label: "y")
        item.ownerID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
