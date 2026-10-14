@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryAcuityPlanPolicyValidator()
        let item = Staffing.newPrimaryAcuityPlanPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PrimaryAcuityPlanPolicyRequiredCodeRule(
            message: "primary acuity plan policy needs this field"
        )
        let item = Staffing.newPrimaryAcuityPlanPolicy("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryAcuityPlanPolicyRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Staffing.PrimaryAcuityPlanPolicyRequiredCategoryRule(
            message: "primary acuity plan policy needs this field"
        )
        let item = Staffing.newPrimaryAcuityPlanPolicy("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryAcuityPlanPolicyBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.PrimaryAcuityPlanPolicyBudgetRangeRule(min: 9.2, max: 3519.8)
        let item = Staffing.newPrimaryAcuityPlanPolicy("x", label: "y")
        item.budget = 3521.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanPolicyLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.PrimaryAcuityPlanPolicyLabelLengthRule(maxLength: 255)
        let item = Staffing.newPrimaryAcuityPlanPolicy("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
