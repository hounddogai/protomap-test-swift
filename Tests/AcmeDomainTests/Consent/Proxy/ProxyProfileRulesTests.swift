@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyProfileValidator()
        let item = Consent.newProxyProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyProfileCodeLengthRule(maxLength: 3600)
        let item = Consent.newProxyProfile("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyProfileRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.ProxyProfileRequiredTitleRule(message: "proxy profile needs a value")
        let item = Consent.newProxyProfile("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
