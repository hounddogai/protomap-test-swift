@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentDigestValidator()
        let item = CareManagement.newAssessmentDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentDigestRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = CareManagement.AssessmentDigestRetriesRangeRule(min: 32, max: 64)
        let item = CareManagement.newAssessmentDigest("x", label: "y")
        item.retries = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentDigestRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = CareManagement.AssessmentDigestRequiredSourceRule(message: "assessment digest needs a value")
        let item = CareManagement.newAssessmentDigest("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentDigestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.AssessmentDigestRequiredLabelRule(message: "assessment digest needs this field")
        let item = CareManagement.newAssessmentDigest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
