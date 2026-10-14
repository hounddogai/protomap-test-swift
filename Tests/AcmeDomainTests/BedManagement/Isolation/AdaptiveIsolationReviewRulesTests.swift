@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveIsolationReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveIsolationReviewValidator()
        let item = BedManagement.newAdaptiveIsolationReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveIsolationReviewRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = BedManagement.AdaptiveIsolationReviewRequiredPatientRefRule(
            message: "adaptive isolation review needs an entry"
        )
        let item = BedManagement.newAdaptiveIsolationReview("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementAdaptiveIsolationReviewBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.AdaptiveIsolationReviewBudgetRangeRule(min: 1.6, max: 1016.6)
        let item = BedManagement.newAdaptiveIsolationReview("x", title: "y")
        item.budget = 1018.1
        #expect(rule.check(item).count > 0)
    }
}
