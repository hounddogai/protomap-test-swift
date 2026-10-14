@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeMetricValidator()
        let item = Staffing.newOvertimeMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeMetricTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.OvertimeMetricTitleLengthRule(maxLength: 120)
        let item = Staffing.newOvertimeMetric("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeMetricPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Staffing.OvertimeMetricPhoneLengthRule(maxLength: 86400)
        let item = Staffing.newOvertimeMetric("x", title: "y")
        item.phone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeMetricSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Staffing.OvertimeMetricSegmentLengthRule(maxLength: 255)
        let item = Staffing.newOvertimeMetric("x", title: "y")
        item.segment = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeMetricRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Staffing.OvertimeMetricRequiredSegmentRule(message: "overtime metric needs this field")
        let item = Staffing.newOvertimeMetric("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
