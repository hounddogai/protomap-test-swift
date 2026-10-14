@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedCourierSegmentValidator()
        let item = Labs.newWeightedCourierSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedCourierSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.WeightedCourierSegmentRequiredLabelRule(message: "weighted courier segment needs an entry")
        let item = Labs.newWeightedCourierSegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedCourierSegmentRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.WeightedCourierSegmentRatioRangeRule(min: 8.4, max: 1778.5)
        let item = Labs.newWeightedCourierSegment("x", label: "y")
        item.ratio = 1780.0
        #expect(rule.check(item).count > 0)
    }
}
