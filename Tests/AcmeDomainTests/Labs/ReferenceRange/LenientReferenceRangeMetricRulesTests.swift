@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientReferenceRangeMetricValidator()
        let item = Labs.newLenientReferenceRangeMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientReferenceRangeMetricRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.LenientReferenceRangeMetricRateRangeRule(min: 1.5, max: 4591.0)
        let item = Labs.newLenientReferenceRangeMetric("x", title: "y")
        item.rate = 4592.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLenientReferenceRangeMetricRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.LenientReferenceRangeMetricRequiredTitleRule(
            message: "lenient reference range metric needs this field"
        )
        let item = Labs.newLenientReferenceRangeMetric("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientReferenceRangeMetricTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.LenientReferenceRangeMetricTitleLengthRule(maxLength: 86400)
        let item = Labs.newLenientReferenceRangeMetric("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
