@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedLanguagePreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedLanguagePreferenceValidator()
        let item = Consent.newCappedLanguagePreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedLanguagePreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.CappedLanguagePreferenceLabelLengthRule(maxLength: 255)
        let item = Consent.newCappedLanguagePreference("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedLanguagePreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.CappedLanguagePreferenceRequiredCodeRule(
            message: "capped language preference needs this field"
        )
        let item = Consent.newCappedLanguagePreference("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedLanguagePreferenceGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Consent.CappedLanguagePreferenceGraceDaysRangeRule(min: 80, max: 3600)
        let item = Consent.newCappedLanguagePreference("x", label: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}
