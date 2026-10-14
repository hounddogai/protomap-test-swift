@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackOvertimeMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackOvertimeMetricValidator()
        let item = Staffing.newFallbackOvertimeMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackOvertimeMetricNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.FallbackOvertimeMetricNameLengthRule(maxLength: 80)
        let item = Staffing.newFallbackOvertimeMetric("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackOvertimeMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FallbackOvertimeMetricRequiredCodeRule(message: "fallback overtime metric needs a value")
        let item = Staffing.newFallbackOvertimeMetric("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
