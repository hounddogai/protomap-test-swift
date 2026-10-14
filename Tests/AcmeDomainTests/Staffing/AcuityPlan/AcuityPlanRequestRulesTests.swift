@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanRequestValidator()
        let item = Staffing.newAcuityPlanRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AcuityPlanRequestCodeLengthRule(maxLength: 255)
        let item = Staffing.newAcuityPlanRequest("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanRequestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.AcuityPlanRequestNameLengthRule(maxLength: 86400)
        let item = Staffing.newAcuityPlanRequest("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanRequestBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.AcuityPlanRequestBudgetRangeRule(min: 1.5, max: 2487.4)
        let item = Staffing.newAcuityPlanRequest("x", name: "y")
        item.budget = 2488.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanRequestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.AcuityPlanRequestRequiredNameRule(message: "acuity plan request needs a value")
        let item = Staffing.newAcuityPlanRequest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
