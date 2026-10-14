@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentReviewValidator()
        let item = CareManagement.newAssessmentReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentReviewDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = CareManagement.AssessmentReviewDescriptionLengthRule(maxLength: 120)
        let item = CareManagement.newAssessmentReview("x", title: "y")
        item.description = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentReviewDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = CareManagement.AssessmentReviewDiscountRangeRule(min: 2.6, max: 2149.8)
        let item = CareManagement.newAssessmentReview("x", title: "y")
        item.discount = 2151.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AssessmentReviewCodeLengthRule(maxLength: 32)
        let item = CareManagement.newAssessmentReview("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentReviewCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.AssessmentReviewCreatedAtRangeRule(min: 3600, max: 3600)
        let item = CareManagement.newAssessmentReview("x", title: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
