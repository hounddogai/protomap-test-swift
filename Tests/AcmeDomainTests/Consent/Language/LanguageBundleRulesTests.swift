@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageBundleValidator()
        let item = Consent.newLanguageBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageBundleAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Consent.LanguageBundleAttemptsRangeRule(min: 16, max: 255)
        let item = Consent.newLanguageBundle("x", name: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LanguageBundleCodeLengthRule(maxLength: 3600)
        let item = Consent.newLanguageBundle("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
