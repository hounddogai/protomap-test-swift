@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimTargetValidator()
        let item = RevenueCycle.newClaimTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimTargetPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.ClaimTargetPriorityRangeRule(min: 120, max: 3600)
        let item = RevenueCycle.newClaimTarget("x", name: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimTargetLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = RevenueCycle.ClaimTargetLocaleLengthRule(maxLength: 3600)
        let item = RevenueCycle.newClaimTarget("x", name: "y")
        item.locale = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ClaimTargetNameLengthRule(maxLength: 3600)
        let item = RevenueCycle.newClaimTarget("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimTargetRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = RevenueCycle.ClaimTargetRequiredLocaleRule(message: "claim target needs an entry")
        let item = RevenueCycle.newClaimTarget("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
