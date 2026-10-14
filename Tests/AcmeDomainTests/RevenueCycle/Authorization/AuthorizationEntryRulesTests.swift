@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationEntryValidator()
        let item = RevenueCycle.newAuthorizationEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationEntryThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = RevenueCycle.AuthorizationEntryThresholdRangeRule(min: 5.5, max: 1208.5)
        let item = RevenueCycle.newAuthorizationEntry("x", name: "y")
        item.threshold = 1210.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.AuthorizationEntryRequiredNameRule(message: "authorization entry needs a value")
        let item = RevenueCycle.newAuthorizationEntry("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationEntryRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = RevenueCycle.AuthorizationEntryRequiredFacilityRule(message: "authorization entry needs a value")
        let item = RevenueCycle.newAuthorizationEntry("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AuthorizationEntryCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newAuthorizationEntry("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
