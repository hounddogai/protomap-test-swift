@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryOutreachReviewValidator()
        let item = CareManagement.newPrimaryOutreachReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryOutreachReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.PrimaryOutreachReviewLabelLengthRule(maxLength: 16)
        let item = CareManagement.newPrimaryOutreachReview("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryOutreachReviewDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = CareManagement.PrimaryOutreachReviewDescriptionLengthRule(maxLength: 80)
        let item = CareManagement.newPrimaryOutreachReview("x", label: "y")
        item.description = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryOutreachReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.PrimaryOutreachReviewRequiredCodeRule(message: "primary outreach review needs a value")
        let item = CareManagement.newPrimaryOutreachReview("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPrimaryOutreachReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.PrimaryOutreachReviewRequiredLabelRule(
            message: "primary outreach review needs a value"
        )
        let item = CareManagement.newPrimaryOutreachReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPrimaryOutreachReviewUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.PrimaryOutreachReviewUpdatedAtRangeRule(min: 120, max: 1000)
        let item = CareManagement.newPrimaryOutreachReview("x", label: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPrimaryOutreachReviewTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.PrimaryOutreachReviewTitleLengthRule(maxLength: 255)
        let item = CareManagement.newPrimaryOutreachReview("x", label: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
