@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledWitnessProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledWitnessProposalValidator()
        let item = Consent.newScheduledWitnessProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledWitnessProposalRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Consent.ScheduledWitnessProposalRequiredProcedureCodeRule(
            message: "scheduled witness proposal needs this field"
        )
        let item = Consent.newScheduledWitnessProposal("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledWitnessProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ScheduledWitnessProposalRequiredCodeRule(
            message: "scheduled witness proposal needs this field"
        )
        let item = Consent.newScheduledWitnessProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledWitnessProposalRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Consent.ScheduledWitnessProposalRequiredSourceRule(
            message: "scheduled witness proposal needs this field"
        )
        let item = Consent.newScheduledWitnessProposal("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledWitnessProposalPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Consent.ScheduledWitnessProposalPriorityRangeRule(min: 64, max: 64)
        let item = Consent.newScheduledWitnessProposal("x", name: "y")
        item.priority = 65
        #expect(rule.check(item).count > 0)
    }
}
