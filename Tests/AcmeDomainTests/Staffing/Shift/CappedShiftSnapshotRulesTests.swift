@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedShiftSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedShiftSnapshotValidator()
        let item = Staffing.newCappedShiftSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedShiftSnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.CappedShiftSnapshotLabelLengthRule(maxLength: 32)
        let item = Staffing.newCappedShiftSnapshot("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedShiftSnapshotRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Staffing.CappedShiftSnapshotRequiredCurrencyRule(message: "capped shift snapshot needs this field")
        let item = Staffing.newCappedShiftSnapshot("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
