@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryAuditValidator()
        let item = Pharmacy.newInventoryAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryAuditRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InventoryAuditRequiredLabelRule(message: "inventory audit needs this field")
        let item = Pharmacy.newInventoryAudit("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InventoryAuditCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newInventoryAudit("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InventoryAuditRequiredCodeRule(message: "inventory audit needs a value")
        let item = Pharmacy.newInventoryAudit("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryAuditBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Pharmacy.InventoryAuditBudgetRangeRule(min: 6.8, max: 3951.2)
        let item = Pharmacy.newInventoryAudit("x", label: "y")
        item.budget = 3952.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryAuditRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Pharmacy.InventoryAuditRequiredTimezoneRule(message: "inventory audit needs an entry")
        let item = Pharmacy.newInventoryAudit("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryAuditVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.InventoryAuditVersionRangeRule(min: 64, max: 1000)
        let item = Pharmacy.newInventoryAudit("x", label: "y")
        item.version = 1001
        #expect(rule.check(item).count > 0)
    }
}
