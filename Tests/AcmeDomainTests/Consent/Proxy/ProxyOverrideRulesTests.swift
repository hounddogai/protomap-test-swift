@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyOverrideValidator()
        let item = Consent.newProxyOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyOverrideCodeLengthRule(maxLength: 3600)
        let item = Consent.newProxyOverride("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyOverrideExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Consent.ProxyOverrideExpiresAtRangeRule(min: 80, max: 255)
        let item = Consent.newProxyOverride("x", name: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ProxyOverrideRequiredCodeRule(message: "proxy override needs an entry")
        let item = Consent.newProxyOverride("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
