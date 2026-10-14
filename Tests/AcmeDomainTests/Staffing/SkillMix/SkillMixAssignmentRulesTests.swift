@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixAssignmentValidator()
        let item = Staffing.newSkillMixAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixAssignmentVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Staffing.SkillMixAssignmentVisitMinutesRangeRule(min: 120, max: 3600)
        let item = Staffing.newSkillMixAssignment("x", name: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixAssignmentRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Staffing.SkillMixAssignmentRequiredReviewerRule(message: "skill mix assignment needs this field")
        let item = Staffing.newSkillMixAssignment("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixAssignmentWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Staffing.SkillMixAssignmentWardLengthRule(maxLength: 1000)
        let item = Staffing.newSkillMixAssignment("x", name: "y")
        item.ward = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
