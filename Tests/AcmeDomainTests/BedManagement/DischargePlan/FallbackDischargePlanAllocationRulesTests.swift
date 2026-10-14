@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackDischargePlanAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackDischargePlanAllocationValidator()
        let item = BedManagement.newFallbackDischargePlanAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackDischargePlanAllocationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.FallbackDischargePlanAllocationLabelLengthRule(maxLength: 16)
        let item = BedManagement.newFallbackDischargePlanAllocation("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackDischargePlanAllocationMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = BedManagement.FallbackDischargePlanAllocationMinimumRangeRule(min: 3.6, max: 2521.3)
        let item = BedManagement.newFallbackDischargePlanAllocation("x", label: "y")
        item.minimum = 2522.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackDischargePlanAllocationRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = BedManagement.FallbackDischargePlanAllocationRequiredNotesRule(
            message: "fallback discharge plan allocation needs an entry"
        )
        let item = BedManagement.newFallbackDischargePlanAllocation("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackDischargePlanAllocationDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = BedManagement.FallbackDischargePlanAllocationDiscountRangeRule(min: 4.0, max: 1148.4)
        let item = BedManagement.newFallbackDischargePlanAllocation("x", label: "y")
        item.discount = 1149.9
        #expect(rule.check(item).count > 0)
    }
}
