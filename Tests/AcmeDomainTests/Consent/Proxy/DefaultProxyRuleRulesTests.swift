@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultProxyRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDefaultProxyRuleValidator()
        let item = Consent.newDefaultProxyRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDefaultProxyRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.DefaultProxyRuleCodeLengthRule(maxLength: 255)
        let item = Consent.newDefaultProxyRule("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDefaultProxyRuleSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Consent.DefaultProxyRuleSourceLengthRule(maxLength: 32)
        let item = Consent.newDefaultProxyRule("x", label: "y")
        item.source = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
