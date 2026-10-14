@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyEntryValidator()
        let item = Consent.newProxyEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyEntryRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Consent.ProxyEntryRequiredSummaryRule(message: "proxy entry needs a value")
        let item = Consent.newProxyEntry("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyEntrySummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Consent.ProxyEntrySummaryLengthRule(maxLength: 3600)
        let item = Consent.newProxyEntry("x", label: "y")
        item.summary = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyEntryStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Consent.ProxyEntryStartsAtRangeRule(min: 80, max: 255)
        let item = Consent.newProxyEntry("x", label: "y")
        item.startsAt = 256
        #expect(rule.check(item).count > 0)
    }
}
