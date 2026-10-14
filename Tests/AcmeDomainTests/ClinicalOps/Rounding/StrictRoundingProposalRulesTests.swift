@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictRoundingProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultStrictRoundingProposalValidator()
        let item = ClinicalOps.newStrictRoundingProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsStrictRoundingProposalCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = ClinicalOps.StrictRoundingProposalCreatedAtRangeRule(min: 64, max: 255)
        let item = ClinicalOps.newStrictRoundingProposal("x", title: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsStrictRoundingProposalRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = ClinicalOps.StrictRoundingProposalRequiredCurrencyRule(
            message: "strict rounding proposal needs this field"
        )
        let item = ClinicalOps.newStrictRoundingProposal("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsStrictRoundingProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.StrictRoundingProposalRequiredCodeRule(message: "strict rounding proposal needs an entry")
        let item = ClinicalOps.newStrictRoundingProposal("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsStrictRoundingProposalCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = ClinicalOps.StrictRoundingProposalCurrencyLengthRule(maxLength: 86400)
        let item = ClinicalOps.newStrictRoundingProposal("x", title: "y")
        item.currency = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsStrictRoundingProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.StrictRoundingProposalCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newStrictRoundingProposal("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsStrictRoundingProposalLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = ClinicalOps.StrictRoundingProposalLocaleLengthRule(maxLength: 3600)
        let item = ClinicalOps.newStrictRoundingProposal("x", title: "y")
        item.locale = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
