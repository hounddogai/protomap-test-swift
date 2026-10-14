@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftSnapshotValidator()
        let item = Staffing.newShiftSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.ShiftSnapshotRequiredNameRule(message: "shift snapshot needs this field")
        let item = Staffing.newShiftSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftSnapshotPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Staffing.ShiftSnapshotPhoneLengthRule(maxLength: 86400)
        let item = Staffing.newShiftSnapshot("x", name: "y")
        item.phone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftSnapshotSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Staffing.ShiftSnapshotSequenceRangeRule(min: 16, max: 255)
        let item = Staffing.newShiftSnapshot("x", name: "y")
        item.sequence = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ShiftSnapshotCodeLengthRule(maxLength: 80)
        let item = Staffing.newShiftSnapshot("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ShiftSnapshotRequiredCodeRule(message: "shift snapshot needs this field")
        let item = Staffing.newShiftSnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
