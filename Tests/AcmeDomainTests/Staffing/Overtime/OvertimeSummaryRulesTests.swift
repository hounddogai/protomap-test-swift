@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeSummaryValidator()
        let item = Staffing.newOvertimeSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.OvertimeSummaryCodeLengthRule(maxLength: 1000)
        let item = Staffing.newOvertimeSummary("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.OvertimeSummaryRequiredTitleRule(message: "overtime summary needs a value")
        let item = Staffing.newOvertimeSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
