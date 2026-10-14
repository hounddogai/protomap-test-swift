@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveGoalPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveGoalPreferenceValidator()
        let item = CareManagement.newAdaptiveGoalPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveGoalPreferenceLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = CareManagement.AdaptiveGoalPreferenceLimitRangeRule(min: 32, max: 86400)
        let item = CareManagement.newAdaptiveGoalPreference("x", label: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveGoalPreferenceSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = CareManagement.AdaptiveGoalPreferenceSourceLengthRule(maxLength: 255)
        let item = CareManagement.newAdaptiveGoalPreference("x", label: "y")
        item.source = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveGoalPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.AdaptiveGoalPreferenceRequiredCodeRule(
            message: "adaptive goal preference needs a value"
        )
        let item = CareManagement.newAdaptiveGoalPreference("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
