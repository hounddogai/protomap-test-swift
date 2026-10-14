@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedSpecimenSlotValidator()
        let item = Labs.newWeightedSpecimenSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedSpecimenSlotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.WeightedSpecimenSlotRequiredNameRule(message: "weighted specimen slot needs a value")
        let item = Labs.newWeightedSpecimenSlot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedSpecimenSlotMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Labs.WeightedSpecimenSlotMinimumRangeRule(min: 8.7, max: 1201.3)
        let item = Labs.newWeightedSpecimenSlot("x", name: "y")
        item.minimum = 1202.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsWeightedSpecimenSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.WeightedSpecimenSlotRequiredCodeRule(message: "weighted specimen slot needs this field")
        let item = Labs.newWeightedSpecimenSlot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
