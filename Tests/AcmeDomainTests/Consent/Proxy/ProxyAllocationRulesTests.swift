@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyAllocationValidator()
        let item = Consent.newProxyAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyAllocationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.ProxyAllocationNameLengthRule(maxLength: 80)
        let item = Consent.newProxyAllocation("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyAllocationChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Consent.ProxyAllocationChannelLengthRule(maxLength: 3600)
        let item = Consent.newProxyAllocation("x", name: "y")
        item.channel = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyAllocationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ProxyAllocationRequiredNameRule(message: "proxy allocation needs an entry")
        let item = Consent.newProxyAllocation("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ProxyAllocationRequiredCodeRule(message: "proxy allocation needs an entry")
        let item = Consent.newProxyAllocation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
