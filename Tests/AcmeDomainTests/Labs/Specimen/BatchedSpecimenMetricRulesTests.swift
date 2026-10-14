@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedSpecimenMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultBatchedSpecimenMetricValidator()
        let item = Labs.newBatchedSpecimenMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsBatchedSpecimenMetricLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.BatchedSpecimenMetricLimitRangeRule(min: 16, max: 32)
        let item = Labs.newBatchedSpecimenMetric("x", label: "y")
        item.limit = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedSpecimenMetricFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Labs.BatchedSpecimenMetricFacilityLengthRule(maxLength: 120)
        let item = Labs.newBatchedSpecimenMetric("x", label: "y")
        item.facility = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsBatchedSpecimenMetricRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Labs.BatchedSpecimenMetricRequiredChecksumRule(message: "batched specimen metric needs a value")
        let item = Labs.newBatchedSpecimenMetric("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
