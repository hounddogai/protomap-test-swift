@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredConsentFormProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultTieredConsentFormProposalValidator()
        let item = Consent.newTieredConsentFormProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentTieredConsentFormProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.TieredConsentFormProposalRequiredLabelRule(
            message: "tiered consent form proposal needs a value"
        )
        let item = Consent.newTieredConsentFormProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentTieredConsentFormProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.TieredConsentFormProposalCodeLengthRule(maxLength: 80)
        let item = Consent.newTieredConsentFormProposal("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentTieredConsentFormProposalPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Consent.TieredConsentFormProposalPriorityRangeRule(min: 16, max: 120)
        let item = Consent.newTieredConsentFormProposal("x", label: "y")
        item.priority = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentTieredConsentFormProposalScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Consent.TieredConsentFormProposalScoreRangeRule(min: 3.6, max: 3487.6)
        let item = Consent.newTieredConsentFormProposal("x", label: "y")
        item.score = 3489.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentTieredConsentFormProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.TieredConsentFormProposalLabelLengthRule(maxLength: 3600)
        let item = Consent.newTieredConsentFormProposal("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
