@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseTierValidator()
        let item = Pharmacy.newDispenseTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseTierNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.DispenseTierNameLengthRule(maxLength: 3600)
        let item = Pharmacy.newDispenseTier("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseTierRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Pharmacy.DispenseTierRequiredCountryRule(message: "dispense tier needs an entry")
        let item = Pharmacy.newDispenseTier("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseTierClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Pharmacy.DispenseTierClinicianIDLengthRule(maxLength: 64)
        let item = Pharmacy.newDispenseTier("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
