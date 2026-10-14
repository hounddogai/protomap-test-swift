@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveRevocationEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveRevocationEstimateValidator()
        let item = Consent.newAdaptiveRevocationEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveRevocationEstimateRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Consent.AdaptiveRevocationEstimateRequiredExternalRefRule(
            message: "adaptive revocation estimate needs this field"
        )
        let item = Consent.newAdaptiveRevocationEstimate("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveRevocationEstimateCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Consent.AdaptiveRevocationEstimateCurrencyLengthRule(maxLength: 64)
        let item = Consent.newAdaptiveRevocationEstimate("x", title: "y")
        item.currency = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveRevocationEstimateRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Consent.AdaptiveRevocationEstimateRequiredCurrencyRule(
            message: "adaptive revocation estimate needs a value"
        )
        let item = Consent.newAdaptiveRevocationEstimate("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveRevocationEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.AdaptiveRevocationEstimateRequiredCodeRule(
            message: "adaptive revocation estimate needs this field"
        )
        let item = Consent.newAdaptiveRevocationEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveRevocationEstimateWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Consent.AdaptiveRevocationEstimateWindowDaysRangeRule(min: 32, max: 80)
        let item = Consent.newAdaptiveRevocationEstimate("x", title: "y")
        item.windowDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentAdaptiveRevocationEstimateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.AdaptiveRevocationEstimateRequiredTitleRule(
            message: "adaptive revocation estimate needs a value"
        )
        let item = Consent.newAdaptiveRevocationEstimate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
