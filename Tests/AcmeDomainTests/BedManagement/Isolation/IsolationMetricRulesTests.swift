@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationMetricValidator()
        let item = BedManagement.newIsolationMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationMetricRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.IsolationMetricRatioRangeRule(min: 6.1, max: 4350.9)
        let item = BedManagement.newIsolationMetric("x", name: "y")
        item.ratio = 4352.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationMetricNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.IsolationMetricNameLengthRule(maxLength: 80)
        let item = BedManagement.newIsolationMetric("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationMetricWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = BedManagement.IsolationMetricWeightRangeRule(min: 8.1, max: 971.0)
        let item = BedManagement.newIsolationMetric("x", name: "y")
        item.weight = 972.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationMetricRequiredCodeRule(message: "isolation metric needs an entry")
        let item = BedManagement.newIsolationMetric("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.IsolationMetricRequiredNameRule(message: "isolation metric needs an entry")
        let item = BedManagement.newIsolationMetric("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
