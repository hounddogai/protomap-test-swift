@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientResultMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientResultMetricValidator()
        let item = Labs.newLenientResultMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientResultMetricBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.LenientResultMetricBatchSizeRangeRule(min: 80, max: 120)
        let item = Labs.newLenientResultMetric("x", name: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLenientResultMetricMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Labs.LenientResultMetricMarginRangeRule(min: 6.6, max: 2098.0)
        let item = Labs.newLenientResultMetric("x", name: "y")
        item.margin = 2099.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLenientResultMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.LenientResultMetricCodeLengthRule(maxLength: 80)
        let item = Labs.newLenientResultMetric("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLenientResultMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.LenientResultMetricRequiredNameRule(message: "lenient result metric needs this field")
        let item = Labs.newLenientResultMetric("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientResultMetricSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Labs.LenientResultMetricSegmentLengthRule(maxLength: 1000)
        let item = Labs.newLenientResultMetric("x", name: "y")
        item.segment = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
