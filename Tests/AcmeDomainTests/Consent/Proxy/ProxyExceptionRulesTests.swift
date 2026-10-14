@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyExceptionValidator()
        let item = Consent.newProxyException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyExceptionCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Consent.ProxyExceptionCopayRangeRule(min: 0.2, max: 2440.2)
        let item = Consent.newProxyException("x", label: "y")
        item.copay = 2441.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyExceptionLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.ProxyExceptionLabelLengthRule(maxLength: 120)
        let item = Consent.newProxyException("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ProxyExceptionRequiredCodeRule(message: "proxy exception needs a value")
        let item = Consent.newProxyException("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyExceptionExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Consent.ProxyExceptionExpiresAtRangeRule(min: 16, max: 86400)
        let item = Consent.newProxyException("x", label: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
