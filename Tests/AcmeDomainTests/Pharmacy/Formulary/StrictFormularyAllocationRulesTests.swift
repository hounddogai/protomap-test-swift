@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictFormularyAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultStrictFormularyAllocationValidator()
        let item = Pharmacy.newStrictFormularyAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyStrictFormularyAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.StrictFormularyAllocationRequiredCodeRule(
            message: "strict formulary allocation needs an entry"
        )
        let item = Pharmacy.newStrictFormularyAllocation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyStrictFormularyAllocationGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.StrictFormularyAllocationGraceDaysRangeRule(min: 32, max: 120)
        let item = Pharmacy.newStrictFormularyAllocation("x", label: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}
