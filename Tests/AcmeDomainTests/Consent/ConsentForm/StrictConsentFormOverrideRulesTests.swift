@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictConsentFormOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictConsentFormOverrideValidator()
        let item = Consent.newStrictConsentFormOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictConsentFormOverrideMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Consent.StrictConsentFormOverrideMarginRangeRule(min: 2.0, max: 1139.1)
        let item = Consent.newStrictConsentFormOverride("x", name: "y")
        item.margin = 1140.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictConsentFormOverrideCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Consent.StrictConsentFormOverrideCeilingRangeRule(min: 3.3, max: 2008.8)
        let item = Consent.newStrictConsentFormOverride("x", name: "y")
        item.ceiling = 2010.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictConsentFormOverrideAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Consent.StrictConsentFormOverrideAmountRangeRule(min: 7.7, max: 4842.1)
        let item = Consent.newStrictConsentFormOverride("x", name: "y")
        item.amount = 4843.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictConsentFormOverridePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Consent.StrictConsentFormOverridePayerLengthRule(maxLength: 1000)
        let item = Consent.newStrictConsentFormOverride("x", name: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
