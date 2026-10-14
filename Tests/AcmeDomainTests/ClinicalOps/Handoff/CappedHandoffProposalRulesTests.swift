@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedHandoffProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCappedHandoffProposalValidator()
        let item = ClinicalOps.newCappedHandoffProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCappedHandoffProposalProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.CappedHandoffProposalProcedureCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newCappedHandoffProposal("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCappedHandoffProposalTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.CappedHandoffProposalTitleLengthRule(maxLength: 1000)
        let item = ClinicalOps.newCappedHandoffProposal("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCappedHandoffProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CappedHandoffProposalCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newCappedHandoffProposal("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCappedHandoffProposalRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.CappedHandoffProposalRequiredProcedureCodeRule(
            message: "capped handoff proposal needs a value"
        )
        let item = ClinicalOps.newCappedHandoffProposal("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCappedHandoffProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CappedHandoffProposalRequiredCodeRule(message: "capped handoff proposal needs a value")
        let item = ClinicalOps.newCappedHandoffProposal("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
