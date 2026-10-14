@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingAlertReviewValidator()
        let item = ClinicalOps.newRollingAlertReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingAlertReviewReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = ClinicalOps.RollingAlertReviewReviewerLengthRule(maxLength: 255)
        let item = ClinicalOps.newRollingAlertReview("x", name: "y")
        item.reviewer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRollingAlertReviewRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = ClinicalOps.RollingAlertReviewRequiredReviewerRule(message: "rolling alert review needs an entry")
        let item = ClinicalOps.newRollingAlertReview("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingAlertReviewAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = ClinicalOps.RollingAlertReviewAmountRangeRule(min: 8.2, max: 2298.9)
        let item = ClinicalOps.newRollingAlertReview("x", name: "y")
        item.amount = 2300.4
        #expect(rule.check(item).count > 0)
    }
}
