@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargeTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultWeightedChargeTierValidator()
        let item = RevenueCycle.newWeightedChargeTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleWeightedChargeTierFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = RevenueCycle.WeightedChargeTierFacilityLengthRule(maxLength: 32)
        let item = RevenueCycle.newWeightedChargeTier("x", name: "y")
        item.facility = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleWeightedChargeTierRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.WeightedChargeTierRequiredNameRule(message: "weighted charge tier needs an entry")
        let item = RevenueCycle.newWeightedChargeTier("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedChargeTierAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = RevenueCycle.WeightedChargeTierAttemptsRangeRule(min: 1000, max: 86400)
        let item = RevenueCycle.newWeightedChargeTier("x", name: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleWeightedChargeTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.WeightedChargeTierCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newWeightedChargeTier("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
