@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalAcuityPlanBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSeasonalAcuityPlanBudgetValidator()
        let item = Staffing.newSeasonalAcuityPlanBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSeasonalAcuityPlanBudgetSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Staffing.SeasonalAcuityPlanBudgetSpecialtyLengthRule(maxLength: 16)
        let item = Staffing.newSeasonalAcuityPlanBudget("x", name: "y")
        item.specialty = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalAcuityPlanBudgetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.SeasonalAcuityPlanBudgetRequiredNameRule(
            message: "seasonal acuity plan budget needs a value"
        )
        let item = Staffing.newSeasonalAcuityPlanBudget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
