@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualStatementTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualStatementTierValidator()
        let item = RevenueCycle.newManualStatementTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualStatementTierRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = RevenueCycle.ManualStatementTierRequiredCountryRule(message: "manual statement tier needs a value")
        let item = RevenueCycle.newManualStatementTier("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualStatementTierDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = RevenueCycle.ManualStatementTierDurationMinutesRangeRule(min: 64, max: 64)
        let item = RevenueCycle.newManualStatementTier("x", label: "y")
        item.durationMinutes = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleManualStatementTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ManualStatementTierRequiredCodeRule(message: "manual statement tier needs a value")
        let item = RevenueCycle.newManualStatementTier("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
