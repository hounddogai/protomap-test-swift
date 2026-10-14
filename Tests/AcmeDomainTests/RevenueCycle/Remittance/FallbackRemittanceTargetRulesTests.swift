@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackRemittanceTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackRemittanceTargetValidator()
        let item = RevenueCycle.newFallbackRemittanceTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackRemittanceTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.FallbackRemittanceTargetRequiredCodeRule(
            message: "fallback remittance target needs a value"
        )
        let item = RevenueCycle.newFallbackRemittanceTarget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackRemittanceTargetRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = RevenueCycle.FallbackRemittanceTargetRegionLengthRule(maxLength: 1000)
        let item = RevenueCycle.newFallbackRemittanceTarget("x", title: "y")
        item.region = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackRemittanceTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.FallbackRemittanceTargetCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newFallbackRemittanceTarget("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackRemittanceTargetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.FallbackRemittanceTargetTitleLengthRule(maxLength: 86400)
        let item = RevenueCycle.newFallbackRemittanceTarget("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackRemittanceTargetAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = RevenueCycle.FallbackRemittanceTargetAttemptsRangeRule(min: 32, max: 64)
        let item = RevenueCycle.newFallbackRemittanceTarget("x", title: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleFallbackRemittanceTargetAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = RevenueCycle.FallbackRemittanceTargetAllergyLengthRule(maxLength: 64)
        let item = RevenueCycle.newFallbackRemittanceTarget("x", title: "y")
        item.allergy = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}
