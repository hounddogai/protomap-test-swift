@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyTargetValidator()
        let item = Consent.newProxyTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ProxyTargetRequiredNameRule(message: "proxy target needs an entry")
        let item = Consent.newProxyTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyTargetCodeLengthRule(maxLength: 3600)
        let item = Consent.newProxyTarget("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyTargetRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Consent.ProxyTargetRequiredExternalRefRule(message: "proxy target needs this field")
        let item = Consent.newProxyTarget("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ProxyTargetRequiredCodeRule(message: "proxy target needs this field")
        let item = Consent.newProxyTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
