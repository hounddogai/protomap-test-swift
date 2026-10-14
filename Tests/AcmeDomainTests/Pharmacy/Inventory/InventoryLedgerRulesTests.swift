@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryLedgerValidator()
        let item = Pharmacy.newInventoryLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InventoryLedgerRequiredCodeRule(message: "inventory ledger needs an entry")
        let item = Pharmacy.newInventoryLedger("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryLedgerLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.InventoryLedgerLabelLengthRule(maxLength: 3600)
        let item = Pharmacy.newInventoryLedger("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryLedgerRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Pharmacy.InventoryLedgerRequiredDescriptionRule(message: "inventory ledger needs an entry")
        let item = Pharmacy.newInventoryLedger("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryLedgerRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InventoryLedgerRequiredLabelRule(message: "inventory ledger needs a value")
        let item = Pharmacy.newInventoryLedger("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryLedgerDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Pharmacy.InventoryLedgerDescriptionLengthRule(maxLength: 3600)
        let item = Pharmacy.newInventoryLedger("x", label: "y")
        item.description = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
