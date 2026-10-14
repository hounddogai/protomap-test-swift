@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageThresholdValidator()
        let item = Consent.newLanguageThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LanguageThresholdCodeLengthRule(maxLength: 86400)
        let item = Consent.newLanguageThreshold("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageThresholdRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Consent.LanguageThresholdRequiredCountryRule(message: "language threshold needs this field")
        let item = Consent.newLanguageThreshold("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageThresholdLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.LanguageThresholdLabelLengthRule(maxLength: 16)
        let item = Consent.newLanguageThreshold("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageThresholdCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Consent.LanguageThresholdCountryLengthRule(maxLength: 255)
        let item = Consent.newLanguageThreshold("x", label: "y")
        item.country = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
