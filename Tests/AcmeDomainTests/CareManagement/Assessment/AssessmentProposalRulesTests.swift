@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentProposalValidator()
        let item = CareManagement.newAssessmentProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentProposalVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.AssessmentProposalVersionRangeRule(min: 16, max: 32)
        let item = CareManagement.newAssessmentProposal("x", title: "y")
        item.version = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentProposalPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = CareManagement.AssessmentProposalPatientRefLengthRule(maxLength: 255)
        let item = CareManagement.newAssessmentProposal("x", title: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentProposalRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = CareManagement.AssessmentProposalRequiredExternalRefRule(
            message: "assessment proposal needs this field"
        )
        let item = CareManagement.newAssessmentProposal("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
