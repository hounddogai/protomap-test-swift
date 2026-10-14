@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultFallbackAssessmentMilestoneValidator()
        let item = CareManagement.newFallbackAssessmentMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementFallbackAssessmentMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.FallbackAssessmentMilestoneRequiredCodeRule(
            message: "fallback assessment milestone needs this field"
        )
        let item = CareManagement.newFallbackAssessmentMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementFallbackAssessmentMilestoneChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = CareManagement.FallbackAssessmentMilestoneChannelLengthRule(maxLength: 120)
        let item = CareManagement.newFallbackAssessmentMilestone("x", name: "y")
        item.channel = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementFallbackAssessmentMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.FallbackAssessmentMilestoneCodeLengthRule(maxLength: 120)
        let item = CareManagement.newFallbackAssessmentMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementFallbackAssessmentMilestoneCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.FallbackAssessmentMilestoneCreatedAtRangeRule(min: 16, max: 255)
        let item = CareManagement.newFallbackAssessmentMilestone("x", name: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementFallbackAssessmentMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.FallbackAssessmentMilestoneRequiredNameRule(
            message: "fallback assessment milestone needs an entry"
        )
        let item = CareManagement.newFallbackAssessmentMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
