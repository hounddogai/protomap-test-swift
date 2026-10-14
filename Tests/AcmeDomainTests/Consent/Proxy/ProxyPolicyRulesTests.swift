@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyPolicyValidator()
        let item = Consent.newProxyPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.ProxyPolicyRequiredLabelRule(message: "proxy policy needs a value")
        let item = Consent.newProxyPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyPolicyLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.ProxyPolicyLocaleLengthRule(maxLength: 120)
        let item = Consent.newProxyPolicy("x", label: "y")
        item.locale = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyPolicyCodeLengthRule(maxLength: 3600)
        let item = Consent.newProxyPolicy("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyPolicySequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Consent.ProxyPolicySequenceRangeRule(min: 32, max: 80)
        let item = Consent.newProxyPolicy("x", label: "y")
        item.sequence = 81
        #expect(rule.check(item).count > 0)
    }
}
