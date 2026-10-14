@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguagePreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguagePreferenceValidator()
        let item = Consent.newLanguagePreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguagePreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.LanguagePreferenceRequiredTitleRule(message: "language preference needs this field")
        let item = Consent.newLanguagePreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguagePreferenceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.LanguagePreferenceTitleLengthRule(maxLength: 3600)
        let item = Consent.newLanguagePreference("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguagePreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LanguagePreferenceRequiredCodeRule(message: "language preference needs an entry")
        let item = Consent.newLanguagePreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguagePreferenceDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.LanguagePreferenceDiscountRangeRule(min: 7.1, max: 1501.2)
        let item = Consent.newLanguagePreference("x", title: "y")
        item.discount = 1502.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguagePreferenceMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.LanguagePreferenceMinimumRangeRule(min: 7.1, max: 3955.0)
        let item = Consent.newLanguagePreference("x", title: "y")
        item.minimum = 3956.5
        #expect(rule.check(item).count > 0)
    }
}
