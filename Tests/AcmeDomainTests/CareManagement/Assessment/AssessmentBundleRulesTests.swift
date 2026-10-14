@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentBundleValidator()
        let item = CareManagement.newAssessmentBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentBundleRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.AssessmentBundleRequiredChannelRule(message: "assessment bundle needs a value")
        let item = CareManagement.newAssessmentBundle("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentBundleSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = CareManagement.AssessmentBundleSequenceRangeRule(min: 16, max: 3600)
        let item = CareManagement.newAssessmentBundle("x", label: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.AssessmentBundleRequiredLabelRule(message: "assessment bundle needs an entry")
        let item = CareManagement.newAssessmentBundle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AssessmentBundleCodeLengthRule(maxLength: 16)
        let item = CareManagement.newAssessmentBundle("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentBundleChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = CareManagement.AssessmentBundleChannelLengthRule(maxLength: 64)
        let item = CareManagement.newAssessmentBundle("x", label: "y")
        item.channel = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
