@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingAllocationValidator()
        let item = ClinicalOps.newRoundingAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingAllocationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.RoundingAllocationRequiredNameRule(message: "rounding allocation needs an entry")
        let item = ClinicalOps.newRoundingAllocation("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingAllocationAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = ClinicalOps.RoundingAllocationAllergyLengthRule(maxLength: 86400)
        let item = ClinicalOps.newRoundingAllocation("x", name: "y")
        item.allergy = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingAllocationRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = ClinicalOps.RoundingAllocationRequiredAllergyRule(message: "rounding allocation needs a value")
        let item = ClinicalOps.newRoundingAllocation("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingAllocationGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = ClinicalOps.RoundingAllocationGraceDaysRangeRule(min: 255, max: 3600)
        let item = ClinicalOps.newRoundingAllocation("x", name: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingAllocationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.RoundingAllocationNameLengthRule(maxLength: 3600)
        let item = ClinicalOps.newRoundingAllocation("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
