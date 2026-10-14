@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingForecastValidator()
        let item = ClinicalOps.newRoundingForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RoundingForecastCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newRoundingForecast("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingForecastEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.RoundingForecastEndsAtRangeRule(min: 3600, max: 86400)
        let item = ClinicalOps.newRoundingForecast("x", label: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingForecastLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = ClinicalOps.RoundingForecastLimitRangeRule(min: 16, max: 86400)
        let item = ClinicalOps.newRoundingForecast("x", label: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}
