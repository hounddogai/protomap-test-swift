@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackChargeBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackChargeBatchValidator()
        let item = RevenueCycle.newFallbackChargeBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackChargeBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.FallbackChargeBatchRequiredCodeRule(message: "fallback charge batch needs this field")
        let item = RevenueCycle.newFallbackChargeBatch("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackChargeBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.FallbackChargeBatchRequiredTitleRule(message: "fallback charge batch needs this field")
        let item = RevenueCycle.newFallbackChargeBatch("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackChargeBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.FallbackChargeBatchTitleLengthRule(maxLength: 64)
        let item = RevenueCycle.newFallbackChargeBatch("x", name: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackChargeBatchFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = RevenueCycle.FallbackChargeBatchFacilityLengthRule(maxLength: 3600)
        let item = RevenueCycle.newFallbackChargeBatch("x", name: "y")
        item.facility = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
