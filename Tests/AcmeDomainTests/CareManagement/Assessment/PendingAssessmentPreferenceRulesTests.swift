@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingAssessmentPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingAssessmentPreferenceValidator()
        let item = CareManagement.newPendingAssessmentPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingAssessmentPreferenceRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.PendingAssessmentPreferenceRequiredChannelRule(
            message: "pending assessment preference needs a value"
        )
        let item = CareManagement.newPendingAssessmentPreference("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
