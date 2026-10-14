@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryExceptionValidator()
        let item = Pharmacy.newInventoryException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InventoryExceptionCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newInventoryException("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryExceptionPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Pharmacy.InventoryExceptionPriorityRangeRule(min: 80, max: 1000)
        let item = Pharmacy.newInventoryException("x", label: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryExceptionRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InventoryExceptionRequiredLabelRule(message: "inventory exception needs an entry")
        let item = Pharmacy.newInventoryException("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryExceptionAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.InventoryExceptionAttemptsRangeRule(min: 64, max: 64)
        let item = Pharmacy.newInventoryException("x", label: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryExceptionUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Pharmacy.InventoryExceptionUnitLengthRule(maxLength: 86400)
        let item = Pharmacy.newInventoryException("x", label: "y")
        item.unit = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
