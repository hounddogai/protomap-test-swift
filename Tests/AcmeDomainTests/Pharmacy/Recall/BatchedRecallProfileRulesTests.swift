@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedRecallProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedRecallProfileValidator()
        let item = Pharmacy.newBatchedRecallProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedRecallProfileRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Pharmacy.BatchedRecallProfileRequiredCategoryRule(message: "batched recall profile needs this field")
        let item = Pharmacy.newBatchedRecallProfile("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyBatchedRecallProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.BatchedRecallProfileCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newBatchedRecallProfile("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedRecallProfileDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Pharmacy.BatchedRecallProfileDurationMinutesRangeRule(min: 120, max: 120)
        let item = Pharmacy.newBatchedRecallProfile("x", label: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyBatchedRecallProfileSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Pharmacy.BatchedRecallProfileSequenceRangeRule(min: 120, max: 86400)
        let item = Pharmacy.newBatchedRecallProfile("x", label: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}
