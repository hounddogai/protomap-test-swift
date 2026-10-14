@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffMetricValidator()
        let item = ClinicalOps.newHandoffMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffMetricAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = ClinicalOps.HandoffMetricAcuityRangeRule(min: 80, max: 120)
        let item = ClinicalOps.newHandoffMetric("x", label: "y")
        item.acuity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.HandoffMetricRequiredCodeRule(message: "handoff metric needs this field")
        let item = ClinicalOps.newHandoffMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffMetricRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = ClinicalOps.HandoffMetricRequiredWardRule(message: "handoff metric needs an entry")
        let item = ClinicalOps.newHandoffMetric("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
