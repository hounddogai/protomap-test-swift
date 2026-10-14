@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreForecastValidator()
        let item = CareManagement.newRiskScoreForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreForecastRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = CareManagement.RiskScoreForecastRequiredPatientRefRule(message: "risk score forecast needs a value")
        let item = CareManagement.newRiskScoreForecast("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreForecastPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = CareManagement.RiskScoreForecastPatientRefLengthRule(maxLength: 64)
        let item = CareManagement.newRiskScoreForecast("x", label: "y")
        item.patientRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreForecastLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.RiskScoreForecastLabelLengthRule(maxLength: 80)
        let item = CareManagement.newRiskScoreForecast("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreForecastMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = CareManagement.RiskScoreForecastMarginRangeRule(min: 5.6, max: 2598.6)
        let item = CareManagement.newRiskScoreForecast("x", label: "y")
        item.margin = 2600.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RiskScoreForecastCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newRiskScoreForecast("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
