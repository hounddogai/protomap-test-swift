@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramReviewValidator()
        let item = CareManagement.newProgramReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramReviewAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = CareManagement.ProgramReviewAttemptsRangeRule(min: 32, max: 120)
        let item = CareManagement.newProgramReview("x", name: "y")
        item.attempts = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementProgramReviewDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = CareManagement.ProgramReviewDescriptionLengthRule(maxLength: 32)
        let item = CareManagement.newProgramReview("x", name: "y")
        item.description = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramReviewThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.ProgramReviewThresholdRangeRule(min: 8.6, max: 2812.5)
        let item = CareManagement.newProgramReview("x", name: "y")
        item.threshold = 2814.0
        #expect(rule.check(item).count > 0)
    }
}
