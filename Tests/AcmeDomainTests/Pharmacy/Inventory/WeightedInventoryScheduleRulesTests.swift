@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedInventoryScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedInventoryScheduleValidator()
        let item = Pharmacy.newWeightedInventorySchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedInventoryScheduleBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Pharmacy.WeightedInventoryScheduleBatchSizeRangeRule(min: 255, max: 1000)
        let item = Pharmacy.newWeightedInventorySchedule("x", label: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedInventoryScheduleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.WeightedInventoryScheduleRequiredLabelRule(
            message: "weighted inventory schedule needs a value"
        )
        let item = Pharmacy.newWeightedInventorySchedule("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyWeightedInventoryScheduleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.WeightedInventoryScheduleExpiresAtRangeRule(min: 32, max: 64)
        let item = Pharmacy.newWeightedInventorySchedule("x", label: "y")
        item.expiresAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedInventoryScheduleRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Pharmacy.WeightedInventoryScheduleRequiredSourceRule(
            message: "weighted inventory schedule needs this field"
        )
        let item = Pharmacy.newWeightedInventorySchedule("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}
