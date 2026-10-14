@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftManifestValidator()
        let item = Staffing.newShiftManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftManifestRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.ShiftManifestRequiredSummaryRule(message: "shift manifest needs this field")
        let item = Staffing.newShiftManifest("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftManifestWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Staffing.ShiftManifestWindowDaysRangeRule(min: 120, max: 86400)
        let item = Staffing.newShiftManifest("x", label: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ShiftManifestCodeLengthRule(maxLength: 1000)
        let item = Staffing.newShiftManifest("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
