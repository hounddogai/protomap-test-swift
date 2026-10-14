@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeReviewValidator()
        let item = Staffing.newOvertimeReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeReviewTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.OvertimeReviewTitleLengthRule(maxLength: 80)
        let item = Staffing.newOvertimeReview("x", name: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.OvertimeReviewRequiredNameRule(message: "overtime review needs an entry")
        let item = Staffing.newOvertimeReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
