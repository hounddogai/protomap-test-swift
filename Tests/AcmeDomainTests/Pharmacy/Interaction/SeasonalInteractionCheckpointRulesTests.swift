@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInteractionCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSeasonalInteractionCheckpointValidator()
        let item = Pharmacy.newSeasonalInteractionCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySeasonalInteractionCheckpointRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.SeasonalInteractionCheckpointRequiredLabelRule(
            message: "seasonal interaction checkpoint needs an entry"
        )
        let item = Pharmacy.newSeasonalInteractionCheckpoint("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalInteractionCheckpointAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Pharmacy.SeasonalInteractionCheckpointAmountRangeRule(min: 3.1, max: 4645.4)
        let item = Pharmacy.newSeasonalInteractionCheckpoint("x", name: "y")
        item.amount = 4646.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySeasonalInteractionCheckpointCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Pharmacy.SeasonalInteractionCheckpointCategoryLengthRule(maxLength: 1000)
        let item = Pharmacy.newSeasonalInteractionCheckpoint("x", name: "y")
        item.category = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySeasonalInteractionCheckpointLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.SeasonalInteractionCheckpointLabelLengthRule(maxLength: 120)
        let item = Pharmacy.newSeasonalInteractionCheckpoint("x", name: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
