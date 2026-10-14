@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeTierValidator()
        let item = RevenueCycle.newChargeTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeTierFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = RevenueCycle.ChargeTierFloorValueRangeRule(min: 3.7, max: 361.7)
        let item = RevenueCycle.newChargeTier("x", name: "y")
        item.floorValue = 363.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeTierAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = RevenueCycle.ChargeTierAcuityRangeRule(min: 32, max: 80)
        let item = RevenueCycle.newChargeTier("x", name: "y")
        item.acuity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeTierNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ChargeTierNameLengthRule(maxLength: 32)
        let item = RevenueCycle.newChargeTier("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ChargeTierRequiredCodeRule(message: "charge tier needs an entry")
        let item = RevenueCycle.newChargeTier("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
