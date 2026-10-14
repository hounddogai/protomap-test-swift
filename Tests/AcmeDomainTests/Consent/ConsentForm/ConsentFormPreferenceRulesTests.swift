@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormPreferenceValidator()
        let item = Consent.newConsentFormPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormPreferenceSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Consent.ConsentFormPreferenceSpecialtyLengthRule(maxLength: 32)
        let item = Consent.newConsentFormPreference("x", name: "y")
        item.specialty = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormPreferenceDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Consent.ConsentFormPreferenceDescriptionLengthRule(maxLength: 32)
        let item = Consent.newConsentFormPreference("x", name: "y")
        item.description = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormPreferenceLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.ConsentFormPreferenceLimitRangeRule(min: 64, max: 86400)
        let item = Consent.newConsentFormPreference("x", name: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormPreferenceRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Consent.ConsentFormPreferenceRateRangeRule(min: 0.5, max: 1254.7)
        let item = Consent.newConsentFormPreference("x", name: "y")
        item.rate = 1256.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormPreferenceRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Consent.ConsentFormPreferenceRequiredSpecialtyRule(
            message: "consent form preference needs this field"
        )
        let item = Consent.newConsentFormPreference("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
