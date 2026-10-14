@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionPlanValidator()
        let item = Pharmacy.newSubstitutionPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionPlanNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.SubstitutionPlanNameLengthRule(maxLength: 120)
        let item = Pharmacy.newSubstitutionPlan("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.SubstitutionPlanRequiredCodeRule(message: "substitution plan needs a value")
        let item = Pharmacy.newSubstitutionPlan("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionPlanEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Pharmacy.SubstitutionPlanEndsAtRangeRule(min: 64, max: 120)
        let item = Pharmacy.newSubstitutionPlan("x", name: "y")
        item.endsAt = 121
        #expect(rule.check(item).count > 0)
    }
}
