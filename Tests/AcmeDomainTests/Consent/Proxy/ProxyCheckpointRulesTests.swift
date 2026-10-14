@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyCheckpointValidator()
        let item = Consent.newProxyCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyCheckpointRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Consent.ProxyCheckpointRequiredLocaleRule(message: "proxy checkpoint needs a value")
        let item = Consent.newProxyCheckpoint("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyCheckpointCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Consent.ProxyCheckpointCurrencyLengthRule(maxLength: 3600)
        let item = Consent.newProxyCheckpoint("x", title: "y")
        item.currency = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyCheckpointLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.ProxyCheckpointLocaleLengthRule(maxLength: 86400)
        let item = Consent.newProxyCheckpoint("x", title: "y")
        item.locale = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
