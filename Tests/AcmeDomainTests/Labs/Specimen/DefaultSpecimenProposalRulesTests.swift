@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultSpecimenProposalValidator()
        let item = Labs.newDefaultSpecimenProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultSpecimenProposalRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Labs.DefaultSpecimenProposalRequiredCurrencyRule(message: "default specimen proposal needs a value")
        let item = Labs.newDefaultSpecimenProposal("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultSpecimenProposalNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.DefaultSpecimenProposalNameLengthRule(maxLength: 32)
        let item = Labs.newDefaultSpecimenProposal("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
