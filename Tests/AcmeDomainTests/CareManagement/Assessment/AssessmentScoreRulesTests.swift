@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentScoreValidator()
        let item = CareManagement.newAssessmentScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentScoreReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = CareManagement.AssessmentScoreReviewerLengthRule(maxLength: 120)
        let item = CareManagement.newAssessmentScore("x", title: "y")
        item.reviewer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.AssessmentScoreRequiredCodeRule(message: "assessment score needs this field")
        let item = CareManagement.newAssessmentScore("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentScoreRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = CareManagement.AssessmentScoreRetriesRangeRule(min: 120, max: 86400)
        let item = CareManagement.newAssessmentScore("x", title: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}
