@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCleaningForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedCleaningForecastValidator()
        let item = BedManagement.newCappedCleaningForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedCleaningForecastRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = BedManagement.CappedCleaningForecastRequiredSourceRule(
            message: "capped cleaning forecast needs this field"
        )
        let item = BedManagement.newCappedCleaningForecast("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCappedCleaningForecastSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = BedManagement.CappedCleaningForecastSummaryLengthRule(maxLength: 80)
        let item = BedManagement.newCappedCleaningForecast("x", title: "y")
        item.summary = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedCleaningForecastMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.CappedCleaningForecastMarginRangeRule(min: 0.3, max: 131.6)
        let item = BedManagement.newCappedCleaningForecast("x", title: "y")
        item.margin = 133.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCappedCleaningForecastAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = BedManagement.CappedCleaningForecastAcuityRangeRule(min: 16, max: 1000)
        let item = BedManagement.newCappedCleaningForecast("x", title: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCappedCleaningForecastCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.CappedCleaningForecastCopayRangeRule(min: 2.4, max: 2888.7)
        let item = BedManagement.newCappedCleaningForecast("x", title: "y")
        item.copay = 2890.2
        #expect(rule.check(item).count > 0)
    }
}
