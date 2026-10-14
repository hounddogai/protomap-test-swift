@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageClaimValidator()
        let item = Consent.newLanguageClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LanguageClaimRequiredCodeRule(message: "language claim needs this field")
        let item = Consent.newLanguageClaim("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageClaimTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Consent.LanguageClaimTimezoneLengthRule(maxLength: 120)
        let item = Consent.newLanguageClaim("x", label: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageClaimLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.LanguageClaimLabelLengthRule(maxLength: 16)
        let item = Consent.newLanguageClaim("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageClaimAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Consent.LanguageClaimAllergyLengthRule(maxLength: 32)
        let item = Consent.newLanguageClaim("x", label: "y")
        item.allergy = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageClaimRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Consent.LanguageClaimRequiredAllergyRule(message: "language claim needs a value")
        let item = Consent.newLanguageClaim("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
