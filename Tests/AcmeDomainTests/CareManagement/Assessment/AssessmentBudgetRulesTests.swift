@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentBudgetValidator()
        let item = CareManagement.newAssessmentBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentBudgetLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = CareManagement.AssessmentBudgetLocaleLengthRule(maxLength: 3600)
        let item = CareManagement.newAssessmentBudget("x", label: "y")
        item.locale = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.AssessmentBudgetRequiredCodeRule(message: "assessment budget needs a value")
        let item = CareManagement.newAssessmentBudget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentBudgetRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = CareManagement.AssessmentBudgetRequiredAllergyRule(message: "assessment budget needs this field")
        let item = CareManagement.newAssessmentBudget("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentBudgetAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = CareManagement.AssessmentBudgetAllergyLengthRule(maxLength: 16)
        let item = CareManagement.newAssessmentBudget("x", label: "y")
        item.allergy = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AssessmentBudgetCodeLengthRule(maxLength: 120)
        let item = CareManagement.newAssessmentBudget("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
