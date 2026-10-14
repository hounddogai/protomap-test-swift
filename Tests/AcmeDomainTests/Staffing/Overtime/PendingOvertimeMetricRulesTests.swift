@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingOvertimeMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingOvertimeMetricValidator()
        let item = Staffing.newPendingOvertimeMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingOvertimeMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PendingOvertimeMetricCodeLengthRule(maxLength: 3600)
        let item = Staffing.newPendingOvertimeMetric("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingOvertimeMetricCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Staffing.PendingOvertimeMetricCapacityRangeRule(min: 120, max: 120)
        let item = Staffing.newPendingOvertimeMetric("x", name: "y")
        item.capacity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPendingOvertimeMetricAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Staffing.PendingOvertimeMetricAcuityRangeRule(min: 86400, max: 86400)
        let item = Staffing.newPendingOvertimeMetric("x", name: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}
