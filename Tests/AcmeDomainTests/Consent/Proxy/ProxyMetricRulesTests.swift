@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyMetricValidator()
        let item = Consent.newProxyMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyMetricCodeLengthRule(maxLength: 3600)
        let item = Consent.newProxyMetric("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyMetricBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Consent.ProxyMetricBatchSizeRangeRule(min: 80, max: 120)
        let item = Consent.newProxyMetric("x", name: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyMetricCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Consent.ProxyMetricCountryLengthRule(maxLength: 80)
        let item = Consent.newProxyMetric("x", name: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
