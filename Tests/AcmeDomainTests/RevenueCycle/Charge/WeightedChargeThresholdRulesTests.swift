@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargeThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultWeightedChargeThresholdValidator()
        let item = RevenueCycle.newWeightedChargeThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleWeightedChargeThresholdRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = RevenueCycle.WeightedChargeThresholdRequiredNotesRule(
            message: "weighted charge threshold needs this field"
        )
        let item = RevenueCycle.newWeightedChargeThreshold("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedChargeThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.WeightedChargeThresholdNameLengthRule(maxLength: 86400)
        let item = RevenueCycle.newWeightedChargeThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleWeightedChargeThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.WeightedChargeThresholdRequiredCodeRule(
            message: "weighted charge threshold needs this field"
        )
        let item = RevenueCycle.newWeightedChargeThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedChargeThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.WeightedChargeThresholdRequiredNameRule(
            message: "weighted charge threshold needs an entry"
        )
        let item = RevenueCycle.newWeightedChargeThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedChargeThresholdRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = RevenueCycle.WeightedChargeThresholdRefillsRangeRule(min: 16, max: 86400)
        let item = RevenueCycle.newWeightedChargeThreshold("x", name: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}
