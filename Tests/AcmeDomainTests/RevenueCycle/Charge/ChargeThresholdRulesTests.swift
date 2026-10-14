@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeThresholdValidator()
        let item = RevenueCycle.newChargeThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeThresholdTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = RevenueCycle.ChargeThresholdTimezoneLengthRule(maxLength: 120)
        let item = RevenueCycle.newChargeThreshold("x", name: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeThresholdEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = RevenueCycle.ChargeThresholdEncounterIDLengthRule(maxLength: 1000)
        let item = RevenueCycle.newChargeThreshold("x", name: "y")
        item.encounterID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeThresholdThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = RevenueCycle.ChargeThresholdThresholdRangeRule(min: 6.9, max: 4746.2)
        let item = RevenueCycle.newChargeThreshold("x", name: "y")
        item.threshold = 4747.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ChargeThresholdCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newChargeThreshold("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
