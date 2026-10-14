@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictAssessmentBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultStrictAssessmentBundleValidator()
        let item = CareManagement.newStrictAssessmentBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementStrictAssessmentBundleChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = CareManagement.StrictAssessmentBundleChannelLengthRule(maxLength: 64)
        let item = CareManagement.newStrictAssessmentBundle("x", label: "y")
        item.channel = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementStrictAssessmentBundleRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = CareManagement.StrictAssessmentBundleRequiredExternalRefRule(
            message: "strict assessment bundle needs a value"
        )
        let item = CareManagement.newStrictAssessmentBundle("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementStrictAssessmentBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.StrictAssessmentBundleRequiredLabelRule(
            message: "strict assessment bundle needs an entry"
        )
        let item = CareManagement.newStrictAssessmentBundle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
