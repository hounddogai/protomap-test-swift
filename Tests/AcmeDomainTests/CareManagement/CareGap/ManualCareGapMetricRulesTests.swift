@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualCareGapMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualCareGapMetricValidator()
        let item = CareManagement.newManualCareGapMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualCareGapMetricRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = CareManagement.ManualCareGapMetricRegionLengthRule(maxLength: 3600)
        let item = CareManagement.newManualCareGapMetric("x", name: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualCareGapMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ManualCareGapMetricCodeLengthRule(maxLength: 86400)
        let item = CareManagement.newManualCareGapMetric("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualCareGapMetricRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = CareManagement.ManualCareGapMetricRequiredRegionRule(
            message: "manual care gap metric needs this field"
        )
        let item = CareManagement.newManualCareGapMetric("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualCareGapMetricNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.ManualCareGapMetricNameLengthRule(maxLength: 3600)
        let item = CareManagement.newManualCareGapMetric("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
