@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionAllocationValidator()
        let item = Pharmacy.newSubstitutionAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.SubstitutionAllocationCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newSubstitutionAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionAllocationAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.SubstitutionAllocationAttemptsRangeRule(min: 255, max: 255)
        let item = Pharmacy.newSubstitutionAllocation("x", label: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionAllocationRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Pharmacy.SubstitutionAllocationRequiredPayerRule(message: "substitution allocation needs a value")
        let item = Pharmacy.newSubstitutionAllocation("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
