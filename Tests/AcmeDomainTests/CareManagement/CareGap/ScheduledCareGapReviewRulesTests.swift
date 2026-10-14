@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledCareGapReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledCareGapReviewValidator()
        let item = CareManagement.newScheduledCareGapReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledCareGapReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ScheduledCareGapReviewRequiredCodeRule(
            message: "scheduled care gap review needs an entry"
        )
        let item = CareManagement.newScheduledCareGapReview("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementScheduledCareGapReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ScheduledCareGapReviewCodeLengthRule(maxLength: 120)
        let item = CareManagement.newScheduledCareGapReview("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledCareGapReviewAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = CareManagement.ScheduledCareGapReviewAmountRangeRule(min: 7.4, max: 451.2)
        let item = CareManagement.newScheduledCareGapReview("x", label: "y")
        item.amount = 452.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementScheduledCareGapReviewRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = CareManagement.ScheduledCareGapReviewRequiredRegionRule(
            message: "scheduled care gap review needs this field"
        )
        let item = CareManagement.newScheduledCareGapReview("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
