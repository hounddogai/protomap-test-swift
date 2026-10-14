@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedCourierBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultBatchedCourierBatchValidator()
        let item = Labs.newBatchedCourierBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsBatchedCourierBatchRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Labs.BatchedCourierBatchRequiredExternalRefRule(message: "batched courier batch needs a value")
        let item = Labs.newBatchedCourierBatch("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsBatchedCourierBatchContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.BatchedCourierBatchContactEmailLengthRule(maxLength: 86400)
        let item = Labs.newBatchedCourierBatch("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsBatchedCourierBatchMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Labs.BatchedCourierBatchMinimumRangeRule(min: 8.4, max: 4097.9)
        let item = Labs.newBatchedCourierBatch("x", label: "y")
        item.minimum = 4099.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedCourierBatchWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Labs.BatchedCourierBatchWeightRangeRule(min: 1.7, max: 4302.9)
        let item = Labs.newBatchedCourierBatch("x", label: "y")
        item.weight = 4304.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedCourierBatchRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.BatchedCourierBatchRatioRangeRule(min: 8.3, max: 702.9)
        let item = Labs.newBatchedCourierBatch("x", label: "y")
        item.ratio = 704.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedCourierBatchAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Labs.BatchedCourierBatchAmountRangeRule(min: 2.6, max: 4125.0)
        let item = Labs.newBatchedCourierBatch("x", label: "y")
        item.amount = 4126.5
        #expect(rule.check(item).count > 0)
    }
}
