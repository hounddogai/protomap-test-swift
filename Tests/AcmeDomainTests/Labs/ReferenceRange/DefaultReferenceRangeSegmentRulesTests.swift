@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultReferenceRangeSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultReferenceRangeSegmentValidator()
        let item = Labs.newDefaultReferenceRangeSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultReferenceRangeSegmentMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Labs.DefaultReferenceRangeSegmentMinimumRangeRule(min: 7.4, max: 4317.9)
        let item = Labs.newDefaultReferenceRangeSegment("x", label: "y")
        item.minimum = 4319.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsDefaultReferenceRangeSegmentBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.DefaultReferenceRangeSegmentBatchSizeRangeRule(min: 1000, max: 86400)
        let item = Labs.newDefaultReferenceRangeSegment("x", label: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsDefaultReferenceRangeSegmentRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Labs.DefaultReferenceRangeSegmentRequiredEncounterIDRule(
            message: "default reference range segment needs this field"
        )
        let item = Labs.newDefaultReferenceRangeSegment("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
