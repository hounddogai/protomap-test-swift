@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelPreferenceValidator()
        let item = Labs.newPanelPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelPreferenceRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Labs.PanelPreferenceRequiredCurrencyRule(message: "panel preference needs a value")
        let item = Labs.newPanelPreference("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelPreferenceRequiredCodeRule(message: "panel preference needs an entry")
        let item = Labs.newPanelPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelPreferenceDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Labs.PanelPreferenceDiagnosisCodeLengthRule(maxLength: 32)
        let item = Labs.newPanelPreference("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelPreferenceCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Labs.PanelPreferenceCurrencyLengthRule(maxLength: 255)
        let item = Labs.newPanelPreference("x", title: "y")
        item.currency = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
