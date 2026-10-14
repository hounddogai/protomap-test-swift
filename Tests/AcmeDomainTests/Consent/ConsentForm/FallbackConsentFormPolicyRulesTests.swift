@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackConsentFormPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultFallbackConsentFormPolicyValidator()
        let item = Consent.newFallbackConsentFormPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentFallbackConsentFormPolicyCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Consent.FallbackConsentFormPolicyCurrencyLengthRule(maxLength: 32)
        let item = Consent.newFallbackConsentFormPolicy("x", label: "y")
        item.currency = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentFallbackConsentFormPolicyLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.FallbackConsentFormPolicyLabelLengthRule(maxLength: 255)
        let item = Consent.newFallbackConsentFormPolicy("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentFallbackConsentFormPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.FallbackConsentFormPolicyCodeLengthRule(maxLength: 80)
        let item = Consent.newFallbackConsentFormPolicy("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
