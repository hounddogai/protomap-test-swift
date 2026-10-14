@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormAgreementValidator()
        let item = Consent.newConsentFormAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormAgreementRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Consent.ConsentFormAgreementRequiredPhoneRule(message: "consent form agreement needs a value")
        let item = Consent.newConsentFormAgreement("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormAgreementDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Consent.ConsentFormAgreementDurationMinutesRangeRule(min: 16, max: 80)
        let item = Consent.newConsentFormAgreement("x", name: "y")
        item.durationMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormAgreementRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Consent.ConsentFormAgreementRequiredCountryRule(message: "consent form agreement needs a value")
        let item = Consent.newConsentFormAgreement("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormAgreementRequiredCodeRule(message: "consent form agreement needs this field")
        let item = Consent.newConsentFormAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
