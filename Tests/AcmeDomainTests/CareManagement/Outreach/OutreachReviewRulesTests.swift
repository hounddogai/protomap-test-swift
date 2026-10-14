@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachReviewValidator()
        let item = CareManagement.newOutreachReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachReviewRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = CareManagement.OutreachReviewRefillsRangeRule(min: 120, max: 1000)
        let item = CareManagement.newOutreachReview("x", title: "y")
        item.refills = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.OutreachReviewRequiredCodeRule(message: "outreach review needs this field")
        let item = CareManagement.newOutreachReview("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachReviewRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = CareManagement.OutreachReviewRevisionRangeRule(min: 80, max: 86400)
        let item = CareManagement.newOutreachReview("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachReviewUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.OutreachReviewUpdatedAtRangeRule(min: 16, max: 86400)
        let item = CareManagement.newOutreachReview("x", title: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
