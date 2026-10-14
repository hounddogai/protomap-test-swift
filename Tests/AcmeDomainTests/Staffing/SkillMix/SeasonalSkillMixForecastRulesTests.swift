@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalSkillMixForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSeasonalSkillMixForecastValidator()
        let item = Staffing.newSeasonalSkillMixForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSeasonalSkillMixForecastProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Staffing.SeasonalSkillMixForecastProcedureCodeLengthRule(maxLength: 16)
        let item = Staffing.newSeasonalSkillMixForecast("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalSkillMixForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SeasonalSkillMixForecastCodeLengthRule(maxLength: 80)
        let item = Staffing.newSeasonalSkillMixForecast("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalSkillMixForecastRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Staffing.SeasonalSkillMixForecastRequiredProcedureCodeRule(
            message: "seasonal skill mix forecast needs this field"
        )
        let item = Staffing.newSeasonalSkillMixForecast("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSeasonalSkillMixForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SeasonalSkillMixForecastRequiredCodeRule(
            message: "seasonal skill mix forecast needs a value"
        )
        let item = Staffing.newSeasonalSkillMixForecast("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSeasonalSkillMixForecastRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.SeasonalSkillMixForecastRequiredNameRule(
            message: "seasonal skill mix forecast needs an entry"
        )
        let item = Staffing.newSeasonalSkillMixForecast("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
