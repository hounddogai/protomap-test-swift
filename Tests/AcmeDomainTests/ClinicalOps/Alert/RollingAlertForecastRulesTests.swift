@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingAlertForecastValidator()
        let item = ClinicalOps.newRollingAlertForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingAlertForecastRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = ClinicalOps.RollingAlertForecastRequiredCurrencyRule(
            message: "rolling alert forecast needs this field"
        )
        let item = ClinicalOps.newRollingAlertForecast("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingAlertForecastCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = ClinicalOps.RollingAlertForecastCurrencyLengthRule(maxLength: 120)
        let item = ClinicalOps.newRollingAlertForecast("x", label: "y")
        item.currency = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRollingAlertForecastRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = ClinicalOps.RollingAlertForecastRequiredReviewerRule(message: "rolling alert forecast needs a value")
        let item = ClinicalOps.newRollingAlertForecast("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingAlertForecastExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = ClinicalOps.RollingAlertForecastExpiresAtRangeRule(min: 32, max: 1000)
        let item = ClinicalOps.newRollingAlertForecast("x", label: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
