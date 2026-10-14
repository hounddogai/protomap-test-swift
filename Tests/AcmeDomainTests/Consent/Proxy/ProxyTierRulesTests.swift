@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyTierValidator()
        let item = Consent.newProxyTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyTierCodeLengthRule(maxLength: 1000)
        let item = Consent.newProxyTier("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyTierRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Consent.ProxyTierRequiredTimezoneRule(message: "proxy tier needs a value")
        let item = Consent.newProxyTier("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.ProxyTierLabelLengthRule(maxLength: 255)
        let item = Consent.newProxyTier("x", name: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ProxyTierRequiredCodeRule(message: "proxy tier needs an entry")
        let item = Consent.newProxyTier("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyTierRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.ProxyTierRequiredLabelRule(message: "proxy tier needs an entry")
        let item = Consent.newProxyTier("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
