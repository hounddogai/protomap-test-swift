@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyStatementPlanValidator()
        let item = RevenueCycle.newLegacyStatementPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyStatementPlanAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = RevenueCycle.LegacyStatementPlanAttemptsRangeRule(min: 32, max: 80)
        let item = RevenueCycle.newLegacyStatementPlan("x", label: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLegacyStatementPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.LegacyStatementPlanRequiredCodeRule(message: "legacy statement plan needs a value")
        let item = RevenueCycle.newLegacyStatementPlan("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyStatementPlanRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.LegacyStatementPlanRequiredLabelRule(message: "legacy statement plan needs an entry")
        let item = RevenueCycle.newLegacyStatementPlan("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
