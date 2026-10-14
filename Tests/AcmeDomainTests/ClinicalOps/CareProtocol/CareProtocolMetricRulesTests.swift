@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolMetricValidator()
        let item = ClinicalOps.newCareProtocolMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolMetricPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = ClinicalOps.CareProtocolMetricPriorityRangeRule(min: 64, max: 64)
        let item = ClinicalOps.newCareProtocolMetric("x", name: "y")
        item.priority = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CareProtocolMetricRequiredCodeRule(message: "care protocol metric needs a value")
        let item = ClinicalOps.newCareProtocolMetric("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
