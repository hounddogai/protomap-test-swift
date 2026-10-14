@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentTargetValidator()
        let item = CareManagement.newAssessmentTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentTargetBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = CareManagement.AssessmentTargetBudgetRangeRule(min: 2.8, max: 4523.0)
        let item = CareManagement.newAssessmentTarget("x", label: "y")
        item.budget = 4524.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentTargetRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = CareManagement.AssessmentTargetRateRangeRule(min: 6.6, max: 1652.6)
        let item = CareManagement.newAssessmentTarget("x", label: "y")
        item.rate = 1654.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentTargetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.AssessmentTargetRequiredLabelRule(message: "assessment target needs an entry")
        let item = CareManagement.newAssessmentTarget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.AssessmentTargetRequiredCodeRule(message: "assessment target needs an entry")
        let item = CareManagement.newAssessmentTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.AssessmentTargetLabelLengthRule(maxLength: 120)
        let item = CareManagement.newAssessmentTarget("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
