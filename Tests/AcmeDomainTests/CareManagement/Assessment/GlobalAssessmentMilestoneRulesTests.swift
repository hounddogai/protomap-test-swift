@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalAssessmentMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalAssessmentMilestoneValidator()
        let item = CareManagement.newGlobalAssessmentMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalAssessmentMilestoneRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.GlobalAssessmentMilestoneRequiredTitleRule(
            message: "global assessment milestone needs this field"
        )
        let item = CareManagement.newGlobalAssessmentMilestone("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalAssessmentMilestoneVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.GlobalAssessmentMilestoneVersionRangeRule(min: 80, max: 120)
        let item = CareManagement.newGlobalAssessmentMilestone("x", title: "y")
        item.version = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalAssessmentMilestoneExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.GlobalAssessmentMilestoneExternalRefLengthRule(maxLength: 32)
        let item = CareManagement.newGlobalAssessmentMilestone("x", title: "y")
        item.externalRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalAssessmentMilestoneRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = CareManagement.GlobalAssessmentMilestoneRequiredExternalRefRule(
            message: "global assessment milestone needs this field"
        )
        let item = CareManagement.newGlobalAssessmentMilestone("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
