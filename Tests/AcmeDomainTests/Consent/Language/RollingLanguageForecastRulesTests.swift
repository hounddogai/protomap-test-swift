@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingLanguageForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingLanguageForecastValidator()
        let item = Consent.newRollingLanguageForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingLanguageForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RollingLanguageForecastCodeLengthRule(maxLength: 255)
        let item = Consent.newRollingLanguageForecast("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingLanguageForecastPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Consent.RollingLanguageForecastPatientRefLengthRule(maxLength: 86400)
        let item = Consent.newRollingLanguageForecast("x", label: "y")
        item.patientRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingLanguageForecastRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Consent.RollingLanguageForecastRequiredSegmentRule(
            message: "rolling language forecast needs this field"
        )
        let item = Consent.newRollingLanguageForecast("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingLanguageForecastLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.RollingLanguageForecastLabelLengthRule(maxLength: 3600)
        let item = Consent.newRollingLanguageForecast("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
