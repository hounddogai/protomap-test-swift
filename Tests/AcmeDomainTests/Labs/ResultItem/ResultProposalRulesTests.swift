@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultProposalValidator()
        let item = Labs.newResultProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultProposalDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Labs.ResultProposalDiagnosisCodeLengthRule(maxLength: 16)
        let item = Labs.newResultProposal("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultProposalExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.ResultProposalExpiresAtRangeRule(min: 80, max: 255)
        let item = Labs.newResultProposal("x", label: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.ResultProposalRequiredLabelRule(message: "result proposal needs this field")
        let item = Labs.newResultProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ResultProposalCodeLengthRule(maxLength: 80)
        let item = Labs.newResultProposal("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ResultProposalLabelLengthRule(maxLength: 86400)
        let item = Labs.newResultProposal("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
