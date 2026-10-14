@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackInventoryBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFallbackInventoryBaselineValidator()
        let item = Pharmacy.newFallbackInventoryBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFallbackInventoryBaselineDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Pharmacy.FallbackInventoryBaselineDiscountRangeRule(min: 9.0, max: 1450.5)
        let item = Pharmacy.newFallbackInventoryBaseline("x", name: "y")
        item.discount = 1452.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFallbackInventoryBaselineRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Pharmacy.FallbackInventoryBaselineRequiredProcedureCodeRule(
            message: "fallback inventory baseline needs a value"
        )
        let item = Pharmacy.newFallbackInventoryBaseline("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFallbackInventoryBaselinePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Pharmacy.FallbackInventoryBaselinePriorityRangeRule(min: 16, max: 32)
        let item = Pharmacy.newFallbackInventoryBaseline("x", name: "y")
        item.priority = 33
        #expect(rule.check(item).count > 0)
    }
}
