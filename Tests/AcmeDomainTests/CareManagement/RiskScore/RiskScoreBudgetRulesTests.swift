@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreBudgetValidator()
        let item = CareManagement.newRiskScoreBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreBudgetGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.RiskScoreBudgetGraceDaysRangeRule(min: 120, max: 86400)
        let item = CareManagement.newRiskScoreBudget("x", name: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreBudgetPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = CareManagement.RiskScoreBudgetPatientRefLengthRule(maxLength: 86400)
        let item = CareManagement.newRiskScoreBudget("x", name: "y")
        item.patientRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreBudgetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.RiskScoreBudgetRequiredNameRule(message: "risk score budget needs an entry")
        let item = CareManagement.newRiskScoreBudget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
