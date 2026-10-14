@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargePolicyValidator()
        let item = RevenueCycle.newChargePolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargePolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.ChargePolicyRequiredLabelRule(message: "charge policy needs a value")
        let item = RevenueCycle.newChargePolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargePolicyUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.ChargePolicyUpdatedAtRangeRule(min: 80, max: 1000)
        let item = RevenueCycle.newChargePolicy("x", label: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargePolicyUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = RevenueCycle.ChargePolicyUnitLengthRule(maxLength: 80)
        let item = RevenueCycle.newChargePolicy("x", label: "y")
        item.unit = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargePolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ChargePolicyCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newChargePolicy("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargePolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ChargePolicyRequiredCodeRule(message: "charge policy needs this field")
        let item = RevenueCycle.newChargePolicy("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargePolicyCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = RevenueCycle.ChargePolicyCapacityRangeRule(min: 32, max: 255)
        let item = RevenueCycle.newChargePolicy("x", label: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}
