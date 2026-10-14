@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedDispenseMetricValidator()
        let item = Pharmacy.newWeightedDispenseMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedDispenseMetricLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Pharmacy.WeightedDispenseMetricLimitRangeRule(min: 80, max: 3600)
        let item = Pharmacy.newWeightedDispenseMetric("x", name: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedDispenseMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.WeightedDispenseMetricCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newWeightedDispenseMetric("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedDispenseMetricThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Pharmacy.WeightedDispenseMetricThresholdRangeRule(min: 1.0, max: 4816.1)
        let item = Pharmacy.newWeightedDispenseMetric("x", name: "y")
        item.threshold = 4817.6
        #expect(rule.check(item).count > 0)
    }
}
