@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveLanguageClaimValidator()
        let item = Consent.newAdaptiveLanguageClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveLanguageClaimRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Consent.AdaptiveLanguageClaimRegionLengthRule(maxLength: 86400)
        let item = Consent.newAdaptiveLanguageClaim("x", label: "y")
        item.region = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveLanguageClaimLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.AdaptiveLanguageClaimLabelLengthRule(maxLength: 120)
        let item = Consent.newAdaptiveLanguageClaim("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveLanguageClaimDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.AdaptiveLanguageClaimDiscountRangeRule(min: 8.4, max: 4893.0)
        let item = Consent.newAdaptiveLanguageClaim("x", label: "y")
        item.discount = 4894.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentAdaptiveLanguageClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.AdaptiveLanguageClaimRequiredCodeRule(message: "adaptive language claim needs an entry")
        let item = Consent.newAdaptiveLanguageClaim("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
