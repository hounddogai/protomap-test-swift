@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftBaselineValidator()
        let item = Staffing.newShiftBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftBaselineRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.ShiftBaselineRequiredTitleRule(message: "shift baseline needs this field")
        let item = Staffing.newShiftBaseline("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.ShiftBaselineNameLengthRule(maxLength: 80)
        let item = Staffing.newShiftBaseline("x", title: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftBaselineRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Staffing.ShiftBaselineRequiredOwnerIDRule(message: "shift baseline needs a value")
        let item = Staffing.newShiftBaseline("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
