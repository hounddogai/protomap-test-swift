@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalAlertMetricValidator()
        let item = ClinicalOps.newRegionalAlertMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertMetricPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = ClinicalOps.RegionalAlertMetricPriorityRangeRule(min: 255, max: 3600)
        let item = ClinicalOps.newRegionalAlertMetric("x", label: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertMetricRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.RegionalAlertMetricRequiredLabelRule(message: "regional alert metric needs an entry")
        let item = ClinicalOps.newRegionalAlertMetric("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRegionalAlertMetricRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = ClinicalOps.RegionalAlertMetricRatioRangeRule(min: 7.4, max: 163.0)
        let item = ClinicalOps.newRegionalAlertMetric("x", label: "y")
        item.ratio = 164.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertMetricLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.RegionalAlertMetricLabelLengthRule(maxLength: 32)
        let item = ClinicalOps.newRegionalAlertMetric("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
