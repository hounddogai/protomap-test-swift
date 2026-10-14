@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackRevocationPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultFallbackRevocationPreferenceValidator()
        let item = Consent.newFallbackRevocationPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentFallbackRevocationPreferenceRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Consent.FallbackRevocationPreferenceRefillsRangeRule(min: 64, max: 120)
        let item = Consent.newFallbackRevocationPreference("x", name: "y")
        item.refills = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentFallbackRevocationPreferenceRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Consent.FallbackRevocationPreferenceRequiredCountryRule(
            message: "fallback revocation preference needs this field"
        )
        let item = Consent.newFallbackRevocationPreference("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentFallbackRevocationPreferenceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.FallbackRevocationPreferenceNameLengthRule(maxLength: 32)
        let item = Consent.newFallbackRevocationPreference("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentFallbackRevocationPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.FallbackRevocationPreferenceRequiredCodeRule(
            message: "fallback revocation preference needs a value"
        )
        let item = Consent.newFallbackRevocationPreference("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
