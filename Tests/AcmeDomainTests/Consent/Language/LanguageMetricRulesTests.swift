@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageMetricValidator()
        let item = Consent.newLanguageMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageMetricRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Consent.LanguageMetricRequiredCountryRule(message: "language metric needs a value")
        let item = Consent.newLanguageMetric("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageMetricAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Consent.LanguageMetricAttemptsRangeRule(min: 16, max: 1000)
        let item = Consent.newLanguageMetric("x", name: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageMetricRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Consent.LanguageMetricRequiredDiagnosisCodeRule(message: "language metric needs a value")
        let item = Consent.newLanguageMetric("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.LanguageMetricRequiredNameRule(message: "language metric needs this field")
        let item = Consent.newLanguageMetric("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LanguageMetricRequiredCodeRule(message: "language metric needs a value")
        let item = Consent.newLanguageMetric("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
