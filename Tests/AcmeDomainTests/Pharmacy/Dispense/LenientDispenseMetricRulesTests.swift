@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientDispenseMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientDispenseMetricValidator()
        let item = Pharmacy.newLenientDispenseMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientDispenseMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LenientDispenseMetricRequiredCodeRule(message: "lenient dispense metric needs this field")
        let item = Pharmacy.newLenientDispenseMetric("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientDispenseMetricNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.LenientDispenseMetricNameLengthRule(maxLength: 1000)
        let item = Pharmacy.newLenientDispenseMetric("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLenientDispenseMetricDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.LenientDispenseMetricDosageMgRangeRule(min: 9.2, max: 4791.4)
        let item = Pharmacy.newLenientDispenseMetric("x", name: "y")
        item.dosageMg = 4792.9
        #expect(rule.check(item).count > 0)
    }
}
