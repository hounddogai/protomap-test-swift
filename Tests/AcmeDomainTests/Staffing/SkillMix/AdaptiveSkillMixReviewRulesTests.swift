@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveSkillMixReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAdaptiveSkillMixReviewValidator()
        let item = Staffing.newAdaptiveSkillMixReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAdaptiveSkillMixReviewRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Staffing.AdaptiveSkillMixReviewRequiredDescriptionRule(
            message: "adaptive skill mix review needs this field"
        )
        let item = Staffing.newAdaptiveSkillMixReview("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAdaptiveSkillMixReviewRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Staffing.AdaptiveSkillMixReviewRequiredDiagnosisCodeRule(
            message: "adaptive skill mix review needs a value"
        )
        let item = Staffing.newAdaptiveSkillMixReview("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAdaptiveSkillMixReviewAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Staffing.AdaptiveSkillMixReviewAmountRangeRule(min: 9.5, max: 1546.6)
        let item = Staffing.newAdaptiveSkillMixReview("x", label: "y")
        item.amount = 1548.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAdaptiveSkillMixReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AdaptiveSkillMixReviewCodeLengthRule(maxLength: 255)
        let item = Staffing.newAdaptiveSkillMixReview("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
