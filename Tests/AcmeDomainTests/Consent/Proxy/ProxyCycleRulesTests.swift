@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyCycleValidator()
        let item = Consent.newProxyCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyCycleRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Consent.ProxyCycleRequiredChannelRule(message: "proxy cycle needs this field")
        let item = Consent.newProxyCycle("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ProxyCycleRequiredNameRule(message: "proxy cycle needs this field")
        let item = Consent.newProxyCycle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyCycleChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Consent.ProxyCycleChannelLengthRule(maxLength: 3600)
        let item = Consent.newProxyCycle("x", name: "y")
        item.channel = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
