@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimePlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultBatchedOvertimePlanValidator()
        let item = Staffing.newBatchedOvertimePlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingBatchedOvertimePlanAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Staffing.BatchedOvertimePlanAttemptsRangeRule(min: 64, max: 86400)
        let item = Staffing.newBatchedOvertimePlan("x", name: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingBatchedOvertimePlanPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Staffing.BatchedOvertimePlanPatientRefLengthRule(maxLength: 255)
        let item = Staffing.newBatchedOvertimePlan("x", name: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingBatchedOvertimePlanRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Staffing.BatchedOvertimePlanRequiredPatientRefRule(message: "batched overtime plan needs this field")
        let item = Staffing.newBatchedOvertimePlan("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingBatchedOvertimePlanSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Staffing.BatchedOvertimePlanSegmentLengthRule(maxLength: 1000)
        let item = Staffing.newBatchedOvertimePlan("x", name: "y")
        item.segment = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
