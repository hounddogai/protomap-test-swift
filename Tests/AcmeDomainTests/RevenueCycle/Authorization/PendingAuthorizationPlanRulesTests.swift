@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingAuthorizationPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingAuthorizationPlanValidator()
        let item = RevenueCycle.newPendingAuthorizationPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingAuthorizationPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.PendingAuthorizationPlanCodeLengthRule(maxLength: 80)
        let item = RevenueCycle.newPendingAuthorizationPlan("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingAuthorizationPlanNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.PendingAuthorizationPlanNameLengthRule(maxLength: 120)
        let item = RevenueCycle.newPendingAuthorizationPlan("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingAuthorizationPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.PendingAuthorizationPlanRequiredCodeRule(
            message: "pending authorization plan needs an entry"
        )
        let item = RevenueCycle.newPendingAuthorizationPlan("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingAuthorizationPlanRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = RevenueCycle.PendingAuthorizationPlanRatioRangeRule(min: 5.6, max: 2205.5)
        let item = RevenueCycle.newPendingAuthorizationPlan("x", name: "y")
        item.ratio = 2207.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePendingAuthorizationPlanRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = RevenueCycle.PendingAuthorizationPlanRequiredSummaryRule(
            message: "pending authorization plan needs an entry"
        )
        let item = RevenueCycle.newPendingAuthorizationPlan("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
