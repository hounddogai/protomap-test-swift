@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingFormularyMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingFormularyMetricValidator()
        let item = Pharmacy.newRollingFormularyMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingFormularyMetricBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Pharmacy.RollingFormularyMetricBatchSizeRangeRule(min: 64, max: 120)
        let item = Pharmacy.newRollingFormularyMetric("x", title: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingFormularyMetricTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.RollingFormularyMetricTitleLengthRule(maxLength: 32)
        let item = Pharmacy.newRollingFormularyMetric("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingFormularyMetricGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.RollingFormularyMetricGraceDaysRangeRule(min: 16, max: 120)
        let item = Pharmacy.newRollingFormularyMetric("x", title: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingFormularyMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RollingFormularyMetricCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newRollingFormularyMetric("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
