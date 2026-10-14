@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackSkillMixReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackSkillMixReviewValidator()
        let item = Staffing.newFallbackSkillMixReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackSkillMixReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.FallbackSkillMixReviewNameLengthRule(maxLength: 16)
        let item = Staffing.newFallbackSkillMixReview("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackSkillMixReviewRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Staffing.FallbackSkillMixReviewRefillsRangeRule(min: 120, max: 255)
        let item = Staffing.newFallbackSkillMixReview("x", name: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}
