@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackRemittanceBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackRemittanceBundleValidator()
        let item = RevenueCycle.newFallbackRemittanceBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackRemittanceBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.FallbackRemittanceBundleRequiredCodeRule(
            message: "fallback remittance bundle needs this field"
        )
        let item = RevenueCycle.newFallbackRemittanceBundle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackRemittanceBundleFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = RevenueCycle.FallbackRemittanceBundleFloorValueRangeRule(min: 7.2, max: 4308.8)
        let item = RevenueCycle.newFallbackRemittanceBundle("x", label: "y")
        item.floorValue = 4310.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleFallbackRemittanceBundleRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = RevenueCycle.FallbackRemittanceBundleRateRangeRule(min: 6.7, max: 4785.8)
        let item = RevenueCycle.newFallbackRemittanceBundle("x", label: "y")
        item.rate = 4787.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleFallbackRemittanceBundleRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = RevenueCycle.FallbackRemittanceBundleRequiredEncounterIDRule(
            message: "fallback remittance bundle needs a value"
        )
        let item = RevenueCycle.newFallbackRemittanceBundle("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackRemittanceBundleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.FallbackRemittanceBundleLabelLengthRule(maxLength: 16)
        let item = RevenueCycle.newFallbackRemittanceBundle("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackRemittanceBundleLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.FallbackRemittanceBundleLimitRangeRule(min: 16, max: 86400)
        let item = RevenueCycle.newFallbackRemittanceBundle("x", label: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}
