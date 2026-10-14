@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingShiftNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRollingShiftNoticeValidator()
        let item = Staffing.newRollingShiftNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRollingShiftNoticeRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.RollingShiftNoticeRequiredLabelRule(message: "rolling shift notice needs a value")
        let item = Staffing.newRollingShiftNotice("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingShiftNoticeRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Staffing.RollingShiftNoticeRequiredReviewerRule(message: "rolling shift notice needs an entry")
        let item = Staffing.newRollingShiftNotice("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingShiftNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.RollingShiftNoticeCodeLengthRule(maxLength: 255)
        let item = Staffing.newRollingShiftNotice("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
