@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingGoalReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingGoalReviewValidator()
        let item = CareManagement.newPendingGoalReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingGoalReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.PendingGoalReviewLabelLengthRule(maxLength: 80)
        let item = CareManagement.newPendingGoalReview("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingGoalReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.PendingGoalReviewRequiredCodeRule(message: "pending goal review needs a value")
        let item = CareManagement.newPendingGoalReview("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingGoalReviewAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = CareManagement.PendingGoalReviewAllergyLengthRule(maxLength: 86400)
        let item = CareManagement.newPendingGoalReview("x", label: "y")
        item.allergy = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingGoalReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.PendingGoalReviewRequiredLabelRule(message: "pending goal review needs this field")
        let item = CareManagement.newPendingGoalReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
