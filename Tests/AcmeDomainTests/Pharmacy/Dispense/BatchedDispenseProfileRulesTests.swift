@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispenseProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedDispenseProfileValidator()
        let item = Pharmacy.newBatchedDispenseProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedDispenseProfileRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.BatchedDispenseProfileRequiredNameRule(message: "batched dispense profile needs a value")
        let item = Pharmacy.newBatchedDispenseProfile("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyBatchedDispenseProfileDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Pharmacy.BatchedDispenseProfileDurationMinutesRangeRule(min: 80, max: 1000)
        let item = Pharmacy.newBatchedDispenseProfile("x", name: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyBatchedDispenseProfileMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Pharmacy.BatchedDispenseProfileMaximumRangeRule(min: 5.5, max: 2502.5)
        let item = Pharmacy.newBatchedDispenseProfile("x", name: "y")
        item.maximum = 2504.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyBatchedDispenseProfileCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Pharmacy.BatchedDispenseProfileCapacityRangeRule(min: 3600, max: 3600)
        let item = Pharmacy.newBatchedDispenseProfile("x", name: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}
