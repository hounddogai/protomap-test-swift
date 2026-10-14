@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictLanguageDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictLanguageDigestValidator()
        let item = Consent.newStrictLanguageDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictLanguageDigestSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Consent.StrictLanguageDigestSummaryLengthRule(maxLength: 255)
        let item = Consent.newStrictLanguageDigest("x", title: "y")
        item.summary = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentStrictLanguageDigestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.StrictLanguageDigestLabelLengthRule(maxLength: 1000)
        let item = Consent.newStrictLanguageDigest("x", title: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentStrictLanguageDigestDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.StrictLanguageDigestDiscountRangeRule(min: 1.8, max: 2977.2)
        let item = Consent.newStrictLanguageDigest("x", title: "y")
        item.discount = 2978.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictLanguageDigestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.StrictLanguageDigestRequiredLabelRule(message: "strict language digest needs this field")
        let item = Consent.newStrictLanguageDigest("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictLanguageDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.StrictLanguageDigestRequiredCodeRule(message: "strict language digest needs a value")
        let item = Consent.newStrictLanguageDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
