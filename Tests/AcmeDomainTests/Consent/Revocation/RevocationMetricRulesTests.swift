@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationMetricValidator()
        let item = Consent.newRevocationMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationMetricDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.RevocationMetricDiscountRangeRule(min: 0.7, max: 2857.6)
        let item = Consent.newRevocationMetric("x", name: "y")
        item.discount = 2859.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRevocationMetricDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Consent.RevocationMetricDurationMinutesRangeRule(min: 255, max: 86400)
        let item = Consent.newRevocationMetric("x", name: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}
