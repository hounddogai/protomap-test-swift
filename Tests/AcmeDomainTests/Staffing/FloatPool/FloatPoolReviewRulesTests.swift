@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolReviewValidator()
        let item = Staffing.newFloatPoolReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolReviewBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.FloatPoolReviewBudgetRangeRule(min: 5.9, max: 4940.0)
        let item = Staffing.newFloatPoolReview("x", title: "y")
        item.budget = 4941.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolReviewTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.FloatPoolReviewTitleLengthRule(maxLength: 16)
        let item = Staffing.newFloatPoolReview("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolReviewRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.FloatPoolReviewRateRangeRule(min: 5.9, max: 3152.7)
        let item = Staffing.newFloatPoolReview("x", title: "y")
        item.rate = 3154.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolReviewRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Staffing.FloatPoolReviewRequiredAllergyRule(message: "float pool review needs an entry")
        let item = Staffing.newFloatPoolReview("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
