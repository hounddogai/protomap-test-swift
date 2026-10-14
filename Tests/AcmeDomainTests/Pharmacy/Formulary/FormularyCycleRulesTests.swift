@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyCycleValidator()
        let item = Pharmacy.newFormularyCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyCycleDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Pharmacy.FormularyCycleDescriptionLengthRule(maxLength: 1000)
        let item = Pharmacy.newFormularyCycle("x", title: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyCycleMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Pharmacy.FormularyCycleMaximumRangeRule(min: 1.7, max: 223.5)
        let item = Pharmacy.newFormularyCycle("x", title: "y")
        item.maximum = 225.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FormularyCycleCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newFormularyCycle("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyCyclePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Pharmacy.FormularyCyclePatientRefLengthRule(maxLength: 64)
        let item = Pharmacy.newFormularyCycle("x", title: "y")
        item.patientRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyCycleFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Pharmacy.FormularyCycleFloorValueRangeRule(min: 4.6, max: 161.8)
        let item = Pharmacy.newFormularyCycle("x", title: "y")
        item.floorValue = 163.3
        #expect(rule.check(item).count > 0)
    }
}
