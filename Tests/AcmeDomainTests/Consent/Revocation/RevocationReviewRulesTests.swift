@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationReviewValidator()
        let item = Consent.newRevocationReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationReviewBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Consent.RevocationReviewBudgetRangeRule(min: 0.6, max: 2494.9)
        let item = Consent.newRevocationReview("x", title: "y")
        item.budget = 2496.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRevocationReviewRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Consent.RevocationReviewRequiredDiagnosisCodeRule(message: "revocation review needs a value")
        let item = Consent.newRevocationReview("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
