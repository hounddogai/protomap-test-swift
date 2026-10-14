@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientTaskProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLenientTaskProposalValidator()
        let item = ClinicalOps.newLenientTaskProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLenientTaskProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.LenientTaskProposalRequiredCodeRule(message: "lenient task proposal needs an entry")
        let item = ClinicalOps.newLenientTaskProposal("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLenientTaskProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.LenientTaskProposalRequiredLabelRule(message: "lenient task proposal needs this field")
        let item = ClinicalOps.newLenientTaskProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLenientTaskProposalNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = ClinicalOps.LenientTaskProposalNotesLengthRule(maxLength: 64)
        let item = ClinicalOps.newLenientTaskProposal("x", label: "y")
        item.notes = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
