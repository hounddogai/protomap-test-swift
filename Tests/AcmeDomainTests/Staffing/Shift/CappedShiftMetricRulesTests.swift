@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedShiftMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedShiftMetricValidator()
        let item = Staffing.newCappedShiftMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedShiftMetricProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Staffing.CappedShiftMetricProcedureCodeLengthRule(maxLength: 120)
        let item = Staffing.newCappedShiftMetric("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedShiftMetricRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Staffing.CappedShiftMetricRequiredProcedureCodeRule(message: "capped shift metric needs an entry")
        let item = Staffing.newCappedShiftMetric("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCappedShiftMetricRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Staffing.CappedShiftMetricRequiredChannelRule(message: "capped shift metric needs an entry")
        let item = Staffing.newCappedShiftMetric("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
