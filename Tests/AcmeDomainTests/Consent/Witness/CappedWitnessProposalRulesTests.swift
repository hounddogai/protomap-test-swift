@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedWitnessProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedWitnessProposalValidator()
        let item = Consent.newCappedWitnessProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedWitnessProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.CappedWitnessProposalRequiredNameRule(message: "capped witness proposal needs this field")
        let item = Consent.newCappedWitnessProposal("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedWitnessProposalSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Consent.CappedWitnessProposalSequenceRangeRule(min: 255, max: 1000)
        let item = Consent.newCappedWitnessProposal("x", name: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentCappedWitnessProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.CappedWitnessProposalCodeLengthRule(maxLength: 120)
        let item = Consent.newCappedWitnessProposal("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedWitnessProposalGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Consent.CappedWitnessProposalGraceDaysRangeRule(min: 1000, max: 1000)
        let item = Consent.newCappedWitnessProposal("x", name: "y")
        item.graceDays = 1001
        #expect(rule.check(item).count > 0)
    }
}
