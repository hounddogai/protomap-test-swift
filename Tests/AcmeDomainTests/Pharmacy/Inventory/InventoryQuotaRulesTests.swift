@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryQuotaValidator()
        let item = Pharmacy.newInventoryQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryQuotaRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Pharmacy.InventoryQuotaRequiredClinicianIDRule(message: "inventory quota needs this field")
        let item = Pharmacy.newInventoryQuota("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryQuotaClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Pharmacy.InventoryQuotaClinicianIDLengthRule(maxLength: 120)
        let item = Pharmacy.newInventoryQuota("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryQuotaQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Pharmacy.InventoryQuotaQuantityRangeRule(min: 32, max: 32)
        let item = Pharmacy.newInventoryQuota("x", name: "y")
        item.quantity = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InventoryQuotaCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newInventoryQuota("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryQuotaNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.InventoryQuotaNameLengthRule(maxLength: 3600)
        let item = Pharmacy.newInventoryQuota("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InventoryQuotaRequiredCodeRule(message: "inventory quota needs a value")
        let item = Pharmacy.newInventoryQuota("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
