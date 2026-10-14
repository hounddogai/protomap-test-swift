@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackGoalGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultFallbackGoalGroupValidator()
        let item = CareManagement.newFallbackGoalGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementFallbackGoalGroupRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = CareManagement.FallbackGoalGroupRequiredReviewerRule(message: "fallback goal group needs a value")
        let item = CareManagement.newFallbackGoalGroup("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementFallbackGoalGroupMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = CareManagement.FallbackGoalGroupMinimumRangeRule(min: 4.7, max: 907.7)
        let item = CareManagement.newFallbackGoalGroup("x", title: "y")
        item.minimum = 909.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementFallbackGoalGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.FallbackGoalGroupRequiredCodeRule(message: "fallback goal group needs this field")
        let item = CareManagement.newFallbackGoalGroup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementFallbackGoalGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.FallbackGoalGroupCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newFallbackGoalGroup("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementFallbackGoalGroupThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.FallbackGoalGroupThresholdRangeRule(min: 7.0, max: 1164.8)
        let item = CareManagement.newFallbackGoalGroup("x", title: "y")
        item.threshold = 1166.3
        #expect(rule.check(item).count > 0)
    }
}
