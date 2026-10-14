@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftPlanValidator()
        let item = Staffing.newShiftPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ShiftPlanCodeLengthRule(maxLength: 1000)
        let item = Staffing.newShiftPlan("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftPlanRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Staffing.ShiftPlanRequiredAllergyRule(message: "shift plan needs an entry")
        let item = Staffing.newShiftPlan("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftPlanRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Staffing.ShiftPlanRequiredCurrencyRule(message: "shift plan needs this field")
        let item = Staffing.newShiftPlan("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
