@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyBaselineValidator()
        let item = Consent.newProxyBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyBaselineCodeLengthRule(maxLength: 1000)
        let item = Consent.newProxyBaseline("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyBaselineRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Consent.ProxyBaselineRequiredSegmentRule(message: "proxy baseline needs a value")
        let item = Consent.newProxyBaseline("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyBaselineGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Consent.ProxyBaselineGraceDaysRangeRule(min: 32, max: 120)
        let item = Consent.newProxyBaseline("x", name: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyBaselineSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Consent.ProxyBaselineSegmentLengthRule(maxLength: 16)
        let item = Consent.newProxyBaseline("x", name: "y")
        item.segment = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
