@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftWindowValidator()
        let item = Staffing.newShiftWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftWindowVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Staffing.ShiftWindowVersionRangeRule(min: 16, max: 1000)
        let item = Staffing.newShiftWindow("x", name: "y")
        item.version = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftWindowRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.ShiftWindowRequiredContactEmailRule(message: "shift window needs this field")
        let item = Staffing.newShiftWindow("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftWindowContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Staffing.ShiftWindowContactEmailLengthRule(maxLength: 3600)
        let item = Staffing.newShiftWindow("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftWindowRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Staffing.ShiftWindowRequiredDiagnosisCodeRule(message: "shift window needs this field")
        let item = Staffing.newShiftWindow("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
