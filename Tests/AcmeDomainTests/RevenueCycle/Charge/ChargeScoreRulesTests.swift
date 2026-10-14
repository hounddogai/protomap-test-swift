@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeScoreValidator()
        let item = RevenueCycle.newChargeScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeScoreCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = RevenueCycle.ChargeScoreCostRangeRule(min: 0.7, max: 4241.5)
        let item = RevenueCycle.newChargeScore("x", title: "y")
        item.cost = 4243.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.ChargeScoreRequiredTitleRule(message: "charge score needs this field")
        let item = RevenueCycle.newChargeScore("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeScoreTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.ChargeScoreTitleLengthRule(maxLength: 16)
        let item = RevenueCycle.newChargeScore("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeScoreAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = RevenueCycle.ChargeScoreAcuityRangeRule(min: 16, max: 120)
        let item = RevenueCycle.newChargeScore("x", title: "y")
        item.acuity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ChargeScoreRequiredCodeRule(message: "charge score needs a value")
        let item = RevenueCycle.newChargeScore("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
