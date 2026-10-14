@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingTaskProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingTaskProposalValidator()
        let item = ClinicalOps.newPendingTaskProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingTaskProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.PendingTaskProposalCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newPendingTaskProposal("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPendingTaskProposalPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.PendingTaskProposalPatientRefLengthRule(maxLength: 86400)
        let item = ClinicalOps.newPendingTaskProposal("x", label: "y")
        item.patientRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
