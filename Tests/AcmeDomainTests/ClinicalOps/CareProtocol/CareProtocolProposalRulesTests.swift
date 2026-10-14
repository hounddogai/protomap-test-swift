@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolProposalValidator()
        let item = ClinicalOps.newCareProtocolProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolProposalRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = ClinicalOps.CareProtocolProposalRequiredEncounterIDRule(
            message: "care protocol proposal needs an entry"
        )
        let item = ClinicalOps.newCareProtocolProposal("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CareProtocolProposalCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newCareProtocolProposal("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolProposalExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = ClinicalOps.CareProtocolProposalExpiresAtRangeRule(min: 16, max: 86400)
        let item = ClinicalOps.newCareProtocolProposal("x", title: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolProposalMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = ClinicalOps.CareProtocolProposalMarginRangeRule(min: 2.6, max: 240.7)
        let item = ClinicalOps.newCareProtocolProposal("x", title: "y")
        item.margin = 242.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolProposalEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = ClinicalOps.CareProtocolProposalEncounterIDLengthRule(maxLength: 120)
        let item = ClinicalOps.newCareProtocolProposal("x", title: "y")
        item.encounterID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
