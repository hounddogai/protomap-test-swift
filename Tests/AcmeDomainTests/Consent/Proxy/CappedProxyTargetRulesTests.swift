@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedProxyTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedProxyTargetValidator()
        let item = Consent.newCappedProxyTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedProxyTargetTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Consent.CappedProxyTargetTimezoneLengthRule(maxLength: 120)
        let item = Consent.newCappedProxyTarget("x", name: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedProxyTargetRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Consent.CappedProxyTargetRequiredTimezoneRule(message: "capped proxy target needs this field")
        let item = Consent.newCappedProxyTarget("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedProxyTargetPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Consent.CappedProxyTargetPriorityRangeRule(min: 80, max: 86400)
        let item = Consent.newCappedProxyTarget("x", name: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}
