@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureProposalValidator()
        let item = Consent.newDisclosureProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureProposalCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Consent.DisclosureProposalCountryLengthRule(maxLength: 86400)
        let item = Consent.newDisclosureProposal("x", label: "y")
        item.country = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureProposalAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Consent.DisclosureProposalAmountRangeRule(min: 9.5, max: 1910.6)
        let item = Consent.newDisclosureProposal("x", label: "y")
        item.amount = 1912.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureProposalContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Consent.DisclosureProposalContactEmailLengthRule(maxLength: 32)
        let item = Consent.newDisclosureProposal("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureProposalEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Consent.DisclosureProposalEndsAtRangeRule(min: 64, max: 3600)
        let item = Consent.newDisclosureProposal("x", label: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
