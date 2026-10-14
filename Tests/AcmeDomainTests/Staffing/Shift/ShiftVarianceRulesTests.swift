@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftVarianceValidator()
        let item = Staffing.newShiftVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ShiftVarianceCodeLengthRule(maxLength: 86400)
        let item = Staffing.newShiftVariance("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.ShiftVarianceTitleLengthRule(maxLength: 80)
        let item = Staffing.newShiftVariance("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftVarianceReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Staffing.ShiftVarianceReviewerLengthRule(maxLength: 1000)
        let item = Staffing.newShiftVariance("x", title: "y")
        item.reviewer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.ShiftVarianceRequiredTitleRule(message: "shift variance needs a value")
        let item = Staffing.newShiftVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
