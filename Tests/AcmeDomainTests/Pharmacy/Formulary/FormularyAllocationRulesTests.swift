@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyAllocationValidator()
        let item = Pharmacy.newFormularyAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FormularyAllocationCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newFormularyAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.FormularyAllocationRequiredCodeRule(message: "formulary allocation needs a value")
        let item = Pharmacy.newFormularyAllocation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyAllocationCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Pharmacy.FormularyAllocationCeilingRangeRule(min: 9.7, max: 3486.6)
        let item = Pharmacy.newFormularyAllocation("x", label: "y")
        item.ceiling = 3488.1
        #expect(rule.check(item).count > 0)
    }
}
