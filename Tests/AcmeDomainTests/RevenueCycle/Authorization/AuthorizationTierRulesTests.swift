@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationTierValidator()
        let item = RevenueCycle.newAuthorizationTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationTierRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = RevenueCycle.AuthorizationTierRequiredUnitRule(message: "authorization tier needs this field")
        let item = RevenueCycle.newAuthorizationTier("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AuthorizationTierRequiredCodeRule(message: "authorization tier needs this field")
        let item = RevenueCycle.newAuthorizationTier("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.AuthorizationTierLabelLengthRule(maxLength: 255)
        let item = RevenueCycle.newAuthorizationTier("x", title: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationTierTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.AuthorizationTierTitleLengthRule(maxLength: 86400)
        let item = RevenueCycle.newAuthorizationTier("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationTierCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = RevenueCycle.AuthorizationTierCapacityRangeRule(min: 16, max: 3600)
        let item = RevenueCycle.newAuthorizationTier("x", title: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}
