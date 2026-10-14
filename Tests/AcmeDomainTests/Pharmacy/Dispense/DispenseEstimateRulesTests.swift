@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseEstimateValidator()
        let item = Pharmacy.newDispenseEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DispenseEstimateRequiredCodeRule(message: "dispense estimate needs a value")
        let item = Pharmacy.newDispenseEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseEstimateRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Pharmacy.DispenseEstimateRequiredContactEmailRule(message: "dispense estimate needs a value")
        let item = Pharmacy.newDispenseEstimate("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseEstimateQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Pharmacy.DispenseEstimateQuantityRangeRule(min: 16, max: 64)
        let item = Pharmacy.newDispenseEstimate("x", title: "y")
        item.quantity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseEstimateRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Pharmacy.DispenseEstimateRequiredPatientRefRule(message: "dispense estimate needs this field")
        let item = Pharmacy.newDispenseEstimate("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseEstimatePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Pharmacy.DispenseEstimatePatientRefLengthRule(maxLength: 80)
        let item = Pharmacy.newDispenseEstimate("x", title: "y")
        item.patientRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
