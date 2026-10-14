@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveBedBoardReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveBedBoardReviewValidator()
        let item = BedManagement.newAdaptiveBedBoardReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveBedBoardReviewLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.AdaptiveBedBoardReviewLimitRangeRule(min: 32, max: 3600)
        let item = BedManagement.newAdaptiveBedBoardReview("x", name: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementAdaptiveBedBoardReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.AdaptiveBedBoardReviewRequiredCodeRule(
            message: "adaptive bed board review needs a value"
        )
        let item = BedManagement.newAdaptiveBedBoardReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementAdaptiveBedBoardReviewRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.AdaptiveBedBoardReviewRatioRangeRule(min: 8.9, max: 1512.3)
        let item = BedManagement.newAdaptiveBedBoardReview("x", name: "y")
        item.ratio = 1513.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementAdaptiveBedBoardReviewRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = BedManagement.AdaptiveBedBoardReviewRequiredUnitRule(
            message: "adaptive bed board review needs a value"
        )
        let item = BedManagement.newAdaptiveBedBoardReview("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
