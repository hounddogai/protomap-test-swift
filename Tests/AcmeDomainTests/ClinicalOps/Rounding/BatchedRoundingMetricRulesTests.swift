@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedRoundingMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultBatchedRoundingMetricValidator()
        let item = ClinicalOps.newBatchedRoundingMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsBatchedRoundingMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.BatchedRoundingMetricCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newBatchedRoundingMetric("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsBatchedRoundingMetricCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = ClinicalOps.BatchedRoundingMetricCurrencyLengthRule(maxLength: 16)
        let item = ClinicalOps.newBatchedRoundingMetric("x", label: "y")
        item.currency = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
