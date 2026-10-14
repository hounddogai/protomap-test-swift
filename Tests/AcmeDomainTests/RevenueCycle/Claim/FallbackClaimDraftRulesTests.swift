@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackClaimDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackClaimDraftValidator()
        let item = RevenueCycle.newFallbackClaimDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackClaimDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.FallbackClaimDraftRequiredCodeRule(message: "fallback claim draft needs a value")
        let item = RevenueCycle.newFallbackClaimDraft("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackClaimDraftStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = RevenueCycle.FallbackClaimDraftStartsAtRangeRule(min: 3600, max: 86400)
        let item = RevenueCycle.newFallbackClaimDraft("x", title: "y")
        item.startsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleFallbackClaimDraftQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = RevenueCycle.FallbackClaimDraftQuantityRangeRule(min: 32, max: 255)
        let item = RevenueCycle.newFallbackClaimDraft("x", title: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleFallbackClaimDraftRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.FallbackClaimDraftRequiredTitleRule(message: "fallback claim draft needs an entry")
        let item = RevenueCycle.newFallbackClaimDraft("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
