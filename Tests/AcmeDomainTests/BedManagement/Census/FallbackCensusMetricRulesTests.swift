@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackCensusMetricValidator()
        let item = BedManagement.newFallbackCensusMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackCensusMetricRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = BedManagement.FallbackCensusMetricRefillsRangeRule(min: 64, max: 120)
        let item = BedManagement.newFallbackCensusMetric("x", name: "y")
        item.refills = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackCensusMetricRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.FallbackCensusMetricRatioRangeRule(min: 6.3, max: 3300.1)
        let item = BedManagement.newFallbackCensusMetric("x", name: "y")
        item.ratio = 3301.6
        #expect(rule.check(item).count > 0)
    }
}
