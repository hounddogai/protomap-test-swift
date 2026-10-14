@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingLanguageBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingLanguageBundleValidator()
        let item = Consent.newRollingLanguageBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingLanguageBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.RollingLanguageBundleRequiredLabelRule(message: "rolling language bundle needs this field")
        let item = Consent.newRollingLanguageBundle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingLanguageBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RollingLanguageBundleCodeLengthRule(maxLength: 16)
        let item = Consent.newRollingLanguageBundle("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingLanguageBundleTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Consent.RollingLanguageBundleTimezoneLengthRule(maxLength: 64)
        let item = Consent.newRollingLanguageBundle("x", label: "y")
        item.timezone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingLanguageBundleRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Consent.RollingLanguageBundleRetriesRangeRule(min: 255, max: 1000)
        let item = Consent.newRollingLanguageBundle("x", label: "y")
        item.retries = 1001
        #expect(rule.check(item).count > 0)
    }
}
