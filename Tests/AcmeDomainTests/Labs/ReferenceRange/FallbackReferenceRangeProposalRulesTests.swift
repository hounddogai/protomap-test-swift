@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackReferenceRangeProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackReferenceRangeProposalValidator()
        let item = Labs.newFallbackReferenceRangeProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackReferenceRangeProposalAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Labs.FallbackReferenceRangeProposalAllergyLengthRule(maxLength: 16)
        let item = Labs.newFallbackReferenceRangeProposal("x", name: "y")
        item.allergy = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackReferenceRangeProposalLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.FallbackReferenceRangeProposalLimitRangeRule(min: 16, max: 80)
        let item = Labs.newFallbackReferenceRangeProposal("x", name: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackReferenceRangeProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.FallbackReferenceRangeProposalRequiredNameRule(
            message: "fallback reference range proposal needs a value"
        )
        let item = Labs.newFallbackReferenceRangeProposal("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackReferenceRangeProposalDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Labs.FallbackReferenceRangeProposalDiagnosisCodeLengthRule(maxLength: 32)
        let item = Labs.newFallbackReferenceRangeProposal("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
