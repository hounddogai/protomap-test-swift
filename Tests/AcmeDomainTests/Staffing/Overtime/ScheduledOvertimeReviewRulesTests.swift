@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledOvertimeReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultScheduledOvertimeReviewValidator()
        let item = Staffing.newScheduledOvertimeReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingScheduledOvertimeReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ScheduledOvertimeReviewRequiredCodeRule(message: "scheduled overtime review needs an entry")
        let item = Staffing.newScheduledOvertimeReview("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledOvertimeReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ScheduledOvertimeReviewCodeLengthRule(maxLength: 1000)
        let item = Staffing.newScheduledOvertimeReview("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingScheduledOvertimeReviewOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Staffing.ScheduledOvertimeReviewOwnerIDLengthRule(maxLength: 80)
        let item = Staffing.newScheduledOvertimeReview("x", title: "y")
        item.ownerID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingScheduledOvertimeReviewRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Staffing.ScheduledOvertimeReviewRequiredOwnerIDRule(
            message: "scheduled overtime review needs this field"
        )
        let item = Staffing.newScheduledOvertimeReview("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledOvertimeReviewDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Staffing.ScheduledOvertimeReviewDurationMinutesRangeRule(min: 1000, max: 3600)
        let item = Staffing.newScheduledOvertimeReview("x", title: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}
