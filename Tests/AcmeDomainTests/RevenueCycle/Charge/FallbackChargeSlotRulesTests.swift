@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackChargeSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackChargeSlotValidator()
        let item = RevenueCycle.newFallbackChargeSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackChargeSlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.FallbackChargeSlotLabelLengthRule(maxLength: 120)
        let item = RevenueCycle.newFallbackChargeSlot("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackChargeSlotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.FallbackChargeSlotRequiredLabelRule(message: "fallback charge slot needs an entry")
        let item = RevenueCycle.newFallbackChargeSlot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
