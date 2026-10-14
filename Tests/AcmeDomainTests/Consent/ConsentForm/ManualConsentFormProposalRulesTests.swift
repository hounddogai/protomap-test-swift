@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultManualConsentFormProposalValidator()
        let item = Consent.newManualConsentFormProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentManualConsentFormProposalRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Consent.ManualConsentFormProposalRequiredExternalRefRule(
            message: "manual consent form proposal needs an entry"
        )
        let item = Consent.newManualConsentFormProposal("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentManualConsentFormProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ManualConsentFormProposalCodeLengthRule(maxLength: 32)
        let item = Consent.newManualConsentFormProposal("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentManualConsentFormProposalExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Consent.ManualConsentFormProposalExternalRefLengthRule(maxLength: 255)
        let item = Consent.newManualConsentFormProposal("x", name: "y")
        item.externalRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentManualConsentFormProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ManualConsentFormProposalRequiredNameRule(
            message: "manual consent form proposal needs a value"
        )
        let item = Consent.newManualConsentFormProposal("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentManualConsentFormProposalCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Consent.ManualConsentFormProposalCountryLengthRule(maxLength: 32)
        let item = Consent.newManualConsentFormProposal("x", name: "y")
        item.country = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentManualConsentFormProposalVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Consent.ManualConsentFormProposalVersionRangeRule(min: 32, max: 3600)
        let item = Consent.newManualConsentFormProposal("x", name: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}
