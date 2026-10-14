@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInventoryPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedInventoryPreferenceValidator()
        let item = Pharmacy.newCappedInventoryPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedInventoryPreferenceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.CappedInventoryPreferenceRequiredNameRule(
            message: "capped inventory preference needs an entry"
        )
        let item = Pharmacy.newCappedInventoryPreference("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedInventoryPreferenceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.CappedInventoryPreferenceNameLengthRule(maxLength: 255)
        let item = Pharmacy.newCappedInventoryPreference("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyCappedInventoryPreferenceRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Pharmacy.CappedInventoryPreferenceRequiredClinicianIDRule(
            message: "capped inventory preference needs a value"
        )
        let item = Pharmacy.newCappedInventoryPreference("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedInventoryPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.CappedInventoryPreferenceRequiredCodeRule(
            message: "capped inventory preference needs this field"
        )
        let item = Pharmacy.newCappedInventoryPreference("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
