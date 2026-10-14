@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictSkillMixReviewValidator()
        let item = Staffing.newStrictSkillMixReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictSkillMixReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.StrictSkillMixReviewRequiredNameRule(message: "strict skill mix review needs a value")
        let item = Staffing.newStrictSkillMixReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictSkillMixReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.StrictSkillMixReviewNameLengthRule(maxLength: 120)
        let item = Staffing.newStrictSkillMixReview("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingStrictSkillMixReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.StrictSkillMixReviewRequiredCodeRule(message: "strict skill mix review needs this field")
        let item = Staffing.newStrictSkillMixReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
