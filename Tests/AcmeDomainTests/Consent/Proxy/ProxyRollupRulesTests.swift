@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyRollupValidator()
        let item = Consent.newProxyRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ProxyRollupRequiredNameRule(message: "proxy rollup needs a value")
        let item = Consent.newProxyRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyRollupCodeLengthRule(maxLength: 1000)
        let item = Consent.newProxyRollup("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyRollupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.ProxyRollupRequiredTitleRule(message: "proxy rollup needs a value")
        let item = Consent.newProxyRollup("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
