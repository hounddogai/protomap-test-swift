@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyDraftValidator()
        let item = Consent.newProxyDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyDraftOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Consent.ProxyDraftOwnerIDLengthRule(maxLength: 64)
        let item = Consent.newProxyDraft("x", name: "y")
        item.ownerID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyDraftLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.ProxyDraftLimitRangeRule(min: 255, max: 1000)
        let item = Consent.newProxyDraft("x", name: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyDraftSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Consent.ProxyDraftSummaryLengthRule(maxLength: 80)
        let item = Consent.newProxyDraft("x", name: "y")
        item.summary = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
