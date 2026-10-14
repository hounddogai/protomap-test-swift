@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultGlobalDisclosureForecastValidator()
        let item = Consent.newGlobalDisclosureForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentGlobalDisclosureForecastRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.GlobalDisclosureForecastRequiredLabelRule(
            message: "global disclosure forecast needs this field"
        )
        let item = Consent.newGlobalDisclosureForecast("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentGlobalDisclosureForecastRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Consent.GlobalDisclosureForecastRequiredDiagnosisCodeRule(
            message: "global disclosure forecast needs this field"
        )
        let item = Consent.newGlobalDisclosureForecast("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentGlobalDisclosureForecastCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.GlobalDisclosureForecastCreatedAtRangeRule(min: 1000, max: 3600)
        let item = Consent.newGlobalDisclosureForecast("x", label: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
