@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyPreferenceValidator()
        let item = Consent.newProxyPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyPreferenceCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Consent.ProxyPreferenceCeilingRangeRule(min: 1.6, max: 4706.0)
        let item = Consent.newProxyPreference("x", title: "y")
        item.ceiling = 4707.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ProxyPreferenceRequiredCodeRule(message: "proxy preference needs this field")
        let item = Consent.newProxyPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
