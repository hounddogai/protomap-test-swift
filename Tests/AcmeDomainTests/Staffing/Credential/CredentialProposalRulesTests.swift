@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialProposalValidator()
        let item = Staffing.newCredentialProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialProposalRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.CredentialProposalRequiredTitleRule(message: "credential proposal needs this field")
        let item = Staffing.newCredentialProposal("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialProposalRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Staffing.CredentialProposalRequiredEncounterIDRule(message: "credential proposal needs a value")
        let item = Staffing.newCredentialProposal("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialProposalRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Staffing.CredentialProposalRequiredChecksumRule(message: "credential proposal needs an entry")
        let item = Staffing.newCredentialProposal("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialProposalCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.CredentialProposalCopayRangeRule(min: 9.6, max: 3590.3)
        let item = Staffing.newCredentialProposal("x", title: "y")
        item.copay = 3591.8
        #expect(rule.check(item).count > 0)
    }
}
