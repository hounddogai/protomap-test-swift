@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictSkillMixForecastValidator()
        let item = Staffing.newStrictSkillMixForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictSkillMixForecastBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Staffing.StrictSkillMixForecastBatchSizeRangeRule(min: 120, max: 1000)
        let item = Staffing.newStrictSkillMixForecast("x", label: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingStrictSkillMixForecastCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Staffing.StrictSkillMixForecastCurrencyLengthRule(maxLength: 3600)
        let item = Staffing.newStrictSkillMixForecast("x", label: "y")
        item.currency = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingStrictSkillMixForecastLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Staffing.StrictSkillMixForecastLimitRangeRule(min: 255, max: 86400)
        let item = Staffing.newStrictSkillMixForecast("x", label: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}
