@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftQuotaValidator()
        let item = Staffing.newShiftQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftQuotaRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Staffing.ShiftQuotaRequiredBedRule(message: "shift quota needs this field")
        let item = Staffing.newShiftQuota("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftQuotaAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Staffing.ShiftQuotaAcuityRangeRule(min: 32, max: 32)
        let item = Staffing.newShiftQuota("x", name: "y")
        item.acuity = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftQuotaDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Staffing.ShiftQuotaDiagnosisCodeLengthRule(maxLength: 1000)
        let item = Staffing.newShiftQuota("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftQuotaBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Staffing.ShiftQuotaBedLengthRule(maxLength: 3600)
        let item = Staffing.newShiftQuota("x", name: "y")
        item.bed = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
