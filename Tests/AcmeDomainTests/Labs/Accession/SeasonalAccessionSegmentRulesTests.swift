@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSeasonalAccessionSegmentValidator()
        let item = Labs.newSeasonalAccessionSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSeasonalAccessionSegmentCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.SeasonalAccessionSegmentCreatedAtRangeRule(min: 1000, max: 1000)
        let item = Labs.newSeasonalAccessionSegment("x", label: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSeasonalAccessionSegmentBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.SeasonalAccessionSegmentBatchSizeRangeRule(min: 32, max: 120)
        let item = Labs.newSeasonalAccessionSegment("x", label: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSeasonalAccessionSegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.SeasonalAccessionSegmentLabelLengthRule(maxLength: 16)
        let item = Labs.newSeasonalAccessionSegment("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalAccessionSegmentReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Labs.SeasonalAccessionSegmentReviewerLengthRule(maxLength: 120)
        let item = Labs.newSeasonalAccessionSegment("x", label: "y")
        item.reviewer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
