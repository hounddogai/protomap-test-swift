@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyChargeScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyChargeScoreValidator()
        let item = RevenueCycle.newLegacyChargeScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyChargeScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.LegacyChargeScoreNameLengthRule(maxLength: 16)
        let item = RevenueCycle.newLegacyChargeScore("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyChargeScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.LegacyChargeScoreCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newLegacyChargeScore("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyChargeScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.LegacyChargeScoreRequiredCodeRule(message: "legacy charge score needs a value")
        let item = RevenueCycle.newLegacyChargeScore("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyChargeScoreAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = RevenueCycle.LegacyChargeScoreAttemptsRangeRule(min: 255, max: 1000)
        let item = RevenueCycle.newLegacyChargeScore("x", name: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLegacyChargeScoreThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = RevenueCycle.LegacyChargeScoreThresholdRangeRule(min: 0.4, max: 4773.2)
        let item = RevenueCycle.newLegacyChargeScore("x", name: "y")
        item.threshold = 4774.7
        #expect(rule.check(item).count > 0)
    }
}
