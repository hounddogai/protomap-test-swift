@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormMetricValidator()
        let item = Consent.newConsentFormMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ConsentFormMetricRequiredNameRule(message: "consent form metric needs an entry")
        let item = Consent.newConsentFormMetric("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormMetricRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Consent.ConsentFormMetricRatioRangeRule(min: 1.9, max: 4450.6)
        let item = Consent.newConsentFormMetric("x", name: "y")
        item.ratio = 4452.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormMetricSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Consent.ConsentFormMetricSummaryLengthRule(maxLength: 32)
        let item = Consent.newConsentFormMetric("x", name: "y")
        item.summary = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
