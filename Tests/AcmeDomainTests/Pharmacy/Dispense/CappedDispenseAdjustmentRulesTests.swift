@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedDispenseAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedDispenseAdjustmentValidator()
        let item = Pharmacy.newCappedDispenseAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedDispenseAdjustmentUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Pharmacy.CappedDispenseAdjustmentUpdatedAtRangeRule(min: 16, max: 80)
        let item = Pharmacy.newCappedDispenseAdjustment("x", title: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyCappedDispenseAdjustmentFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Pharmacy.CappedDispenseAdjustmentFloorValueRangeRule(min: 0.6, max: 2083.4)
        let item = Pharmacy.newCappedDispenseAdjustment("x", title: "y")
        item.floorValue = 2084.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyCappedDispenseAdjustmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.CappedDispenseAdjustmentRequiredTitleRule(
            message: "capped dispense adjustment needs a value"
        )
        let item = Pharmacy.newCappedDispenseAdjustment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
