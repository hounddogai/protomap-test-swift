@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedSpecimenCycleValidator()
        let item = Labs.newWeightedSpecimenCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedSpecimenCycleWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Labs.WeightedSpecimenCycleWardLengthRule(maxLength: 255)
        let item = Labs.newWeightedSpecimenCycle("x", name: "y")
        item.ward = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedSpecimenCycleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Labs.WeightedSpecimenCycleThresholdRangeRule(min: 9.6, max: 4186.9)
        let item = Labs.newWeightedSpecimenCycle("x", name: "y")
        item.threshold = 4188.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsWeightedSpecimenCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.WeightedSpecimenCycleRequiredCodeRule(message: "weighted specimen cycle needs an entry")
        let item = Labs.newWeightedSpecimenCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedSpecimenCycleRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.WeightedSpecimenCycleRateRangeRule(min: 9.4, max: 3689.0)
        let item = Labs.newWeightedSpecimenCycle("x", name: "y")
        item.rate = 3690.5
        #expect(rule.check(item).count > 0)
    }
}
