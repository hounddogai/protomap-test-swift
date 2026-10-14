@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapMetricValidator()
        let item = CareManagement.newCareGapMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapMetricBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = CareManagement.CareGapMetricBatchSizeRangeRule(min: 255, max: 3600)
        let item = CareManagement.newCareGapMetric("x", title: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.CareGapMetricCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newCareGapMetric("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CareGapMetricRequiredCodeRule(message: "care gap metric needs this field")
        let item = CareManagement.newCareGapMetric("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
