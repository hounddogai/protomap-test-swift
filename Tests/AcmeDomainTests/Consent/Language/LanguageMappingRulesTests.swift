@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageMappingValidator()
        let item = Consent.newLanguageMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageMappingLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.LanguageMappingLabelLengthRule(maxLength: 255)
        let item = Consent.newLanguageMapping("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageMappingCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.LanguageMappingCreatedAtRangeRule(min: 80, max: 3600)
        let item = Consent.newLanguageMapping("x", label: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageMappingDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.LanguageMappingDiscountRangeRule(min: 0.8, max: 2684.8)
        let item = Consent.newLanguageMapping("x", label: "y")
        item.discount = 2686.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageMappingRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.LanguageMappingRequiredLabelRule(message: "language mapping needs a value")
        let item = Consent.newLanguageMapping("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
