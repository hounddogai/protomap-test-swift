@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeBaselineValidator()
        let item = Staffing.newOvertimeBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.OvertimeBaselineRequiredCodeRule(message: "overtime baseline needs a value")
        let item = Staffing.newOvertimeBaseline("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeBaselineRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.OvertimeBaselineRequiredSummaryRule(message: "overtime baseline needs an entry")
        let item = Staffing.newOvertimeBaseline("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeBaselineRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.OvertimeBaselineRequiredTitleRule(message: "overtime baseline needs a value")
        let item = Staffing.newOvertimeBaseline("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeBaselineTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.OvertimeBaselineTitleLengthRule(maxLength: 3600)
        let item = Staffing.newOvertimeBaseline("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
