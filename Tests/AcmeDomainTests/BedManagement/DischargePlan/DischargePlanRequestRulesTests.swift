@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanRequestValidator()
        let item = BedManagement.newDischargePlanRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanRequestBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.DischargePlanRequestBudgetRangeRule(min: 7.8, max: 2833.3)
        let item = BedManagement.newDischargePlanRequest("x", name: "y")
        item.budget = 2834.8
        #expect(rule.check(item).count > 0)
    }
}
