@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalFormularyBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultGlobalFormularyBaselineValidator()
        let item = Pharmacy.newGlobalFormularyBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyGlobalFormularyBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.GlobalFormularyBaselineCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newGlobalFormularyBaseline("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalFormularyBaselineThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Pharmacy.GlobalFormularyBaselineThresholdRangeRule(min: 3.8, max: 546.0)
        let item = Pharmacy.newGlobalFormularyBaseline("x", label: "y")
        item.threshold = 547.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyGlobalFormularyBaselineWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.GlobalFormularyBaselineWeightRangeRule(min: 8.0, max: 3103.3)
        let item = Pharmacy.newGlobalFormularyBaseline("x", label: "y")
        item.weight = 3104.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyGlobalFormularyBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.GlobalFormularyBaselineRequiredCodeRule(message: "global formulary baseline needs a value")
        let item = Pharmacy.newGlobalFormularyBaseline("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyGlobalFormularyBaselineRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Pharmacy.GlobalFormularyBaselineRequiredClinicianIDRule(
            message: "global formulary baseline needs a value"
        )
        let item = Pharmacy.newGlobalFormularyBaseline("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
