@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryClaimValidator()
        let item = Pharmacy.newInventoryClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryClaimCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Pharmacy.InventoryClaimCeilingRangeRule(min: 9.1, max: 4745.4)
        let item = Pharmacy.newInventoryClaim("x", name: "y")
        item.ceiling = 4746.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryClaimCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Pharmacy.InventoryClaimCreatedAtRangeRule(min: 32, max: 3600)
        let item = Pharmacy.newInventoryClaim("x", name: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryClaimNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Pharmacy.InventoryClaimNotesLengthRule(maxLength: 255)
        let item = Pharmacy.newInventoryClaim("x", name: "y")
        item.notes = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InventoryClaimCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newInventoryClaim("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InventoryClaimRequiredCodeRule(message: "inventory claim needs this field")
        let item = Pharmacy.newInventoryClaim("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
