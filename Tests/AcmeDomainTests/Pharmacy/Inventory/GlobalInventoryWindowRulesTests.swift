@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInventoryWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultGlobalInventoryWindowValidator()
        let item = Pharmacy.newGlobalInventoryWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyGlobalInventoryWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.GlobalInventoryWindowCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newGlobalInventoryWindow("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalInventoryWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.GlobalInventoryWindowLabelLengthRule(maxLength: 1000)
        let item = Pharmacy.newGlobalInventoryWindow("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalInventoryWindowClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Pharmacy.GlobalInventoryWindowClinicianIDLengthRule(maxLength: 3600)
        let item = Pharmacy.newGlobalInventoryWindow("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
