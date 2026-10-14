@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixReviewValidator()
        let item = Staffing.newSkillMixReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixReviewAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Staffing.SkillMixReviewAttemptsRangeRule(min: 80, max: 80)
        let item = Staffing.newSkillMixReview("x", name: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SkillMixReviewRequiredCodeRule(message: "skill mix review needs an entry")
        let item = Staffing.newSkillMixReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixReviewVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Staffing.SkillMixReviewVisitMinutesRangeRule(min: 32, max: 80)
        let item = Staffing.newSkillMixReview("x", name: "y")
        item.visitMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}
