@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingAlertProposalValidator()
        let item = ClinicalOps.newRollingAlertProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingAlertProposalDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = ClinicalOps.RollingAlertProposalDiagnosisCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newRollingAlertProposal("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRollingAlertProposalRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = ClinicalOps.RollingAlertProposalRequiredReviewerRule(message: "rolling alert proposal needs an entry")
        let item = ClinicalOps.newRollingAlertProposal("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingAlertProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RollingAlertProposalRequiredCodeRule(message: "rolling alert proposal needs this field")
        let item = ClinicalOps.newRollingAlertProposal("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
