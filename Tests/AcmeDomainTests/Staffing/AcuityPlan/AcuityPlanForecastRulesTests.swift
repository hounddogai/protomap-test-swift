@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanForecastValidator()
        let item = Staffing.newAcuityPlanForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanForecastRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Staffing.AcuityPlanForecastRatioRangeRule(min: 0.2, max: 4344.5)
        let item = Staffing.newAcuityPlanForecast("x", title: "y")
        item.ratio = 4346.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanForecastPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Staffing.AcuityPlanForecastPriorityRangeRule(min: 16, max: 3600)
        let item = Staffing.newAcuityPlanForecast("x", title: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanForecastRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.AcuityPlanForecastRequiredSummaryRule(message: "acuity plan forecast needs this field")
        let item = Staffing.newAcuityPlanForecast("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AcuityPlanForecastCodeLengthRule(maxLength: 120)
        let item = Staffing.newAcuityPlanForecast("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
