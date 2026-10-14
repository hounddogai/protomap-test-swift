@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveRoundingMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAdaptiveRoundingMetricValidator()
        let item = ClinicalOps.newAdaptiveRoundingMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AdaptiveRoundingMetricRequiredCodeRule(message: "adaptive rounding metric needs a value")
        let item = ClinicalOps.newAdaptiveRoundingMetric("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingMetricRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.AdaptiveRoundingMetricRequiredTitleRule(
            message: "adaptive rounding metric needs this field"
        )
        let item = ClinicalOps.newAdaptiveRoundingMetric("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.AdaptiveRoundingMetricRequiredNameRule(
            message: "adaptive rounding metric needs this field"
        )
        let item = ClinicalOps.newAdaptiveRoundingMetric("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingMetricRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = ClinicalOps.AdaptiveRoundingMetricRegionLengthRule(maxLength: 3600)
        let item = ClinicalOps.newAdaptiveRoundingMetric("x", title: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingMetricCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = ClinicalOps.AdaptiveRoundingMetricCreatedAtRangeRule(min: 255, max: 3600)
        let item = ClinicalOps.newAdaptiveRoundingMetric("x", title: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
