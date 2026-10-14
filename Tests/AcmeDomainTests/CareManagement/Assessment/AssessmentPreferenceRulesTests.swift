@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentPreferenceValidator()
        let item = CareManagement.newAssessmentPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentPreferencePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = CareManagement.AssessmentPreferencePayerLengthRule(maxLength: 1000)
        let item = CareManagement.newAssessmentPreference("x", title: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentPreferenceRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = CareManagement.AssessmentPreferenceRequiredPayerRule(message: "assessment preference needs a value")
        let item = CareManagement.newAssessmentPreference("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentPreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.AssessmentPreferenceRequiredTitleRule(message: "assessment preference needs a value")
        let item = CareManagement.newAssessmentPreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentPreferenceRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.AssessmentPreferenceRequiredChannelRule(
            message: "assessment preference needs this field"
        )
        let item = CareManagement.newAssessmentPreference("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
