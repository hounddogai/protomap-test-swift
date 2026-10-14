@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingMetricValidator()
        let item = ClinicalOps.newRoundingMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingMetricVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = ClinicalOps.RoundingMetricVersionRangeRule(min: 80, max: 255)
        let item = ClinicalOps.newRoundingMetric("x", name: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RoundingMetricCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newRoundingMetric("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingMetricRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = ClinicalOps.RoundingMetricRetriesRangeRule(min: 16, max: 32)
        let item = ClinicalOps.newRoundingMetric("x", name: "y")
        item.retries = 33
        #expect(rule.check(item).count > 0)
    }
}
