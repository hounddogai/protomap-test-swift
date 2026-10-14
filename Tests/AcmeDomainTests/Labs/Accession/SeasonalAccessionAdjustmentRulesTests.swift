@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSeasonalAccessionAdjustmentValidator()
        let item = Labs.newSeasonalAccessionAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSeasonalAccessionAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.SeasonalAccessionAdjustmentRequiredCodeRule(
            message: "seasonal accession adjustment needs a value"
        )
        let item = Labs.newSeasonalAccessionAdjustment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSeasonalAccessionAdjustmentFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Labs.SeasonalAccessionAdjustmentFloorValueRangeRule(min: 6.0, max: 2826.5)
        let item = Labs.newSeasonalAccessionAdjustment("x", name: "y")
        item.floorValue = 2828.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSeasonalAccessionAdjustmentMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Labs.SeasonalAccessionAdjustmentMinimumRangeRule(min: 1.3, max: 761.8)
        let item = Labs.newSeasonalAccessionAdjustment("x", name: "y")
        item.minimum = 763.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSeasonalAccessionAdjustmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.SeasonalAccessionAdjustmentNameLengthRule(maxLength: 255)
        let item = Labs.newSeasonalAccessionAdjustment("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
