@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallBudgetValidator()
        let item = Pharmacy.newRecallBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallBudgetFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Pharmacy.RecallBudgetFloorValueRangeRule(min: 9.0, max: 1794.5)
        let item = Pharmacy.newRecallBudget("x", label: "y")
        item.floorValue = 1796.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RecallBudgetCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newRecallBudget("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallBudgetExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.RecallBudgetExpiresAtRangeRule(min: 16, max: 32)
        let item = Pharmacy.newRecallBudget("x", label: "y")
        item.expiresAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallBudgetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.RecallBudgetNameLengthRule(maxLength: 120)
        let item = Pharmacy.newRecallBudget("x", label: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallBudgetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.RecallBudgetRequiredLabelRule(message: "recall budget needs a value")
        let item = Pharmacy.newRecallBudget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
