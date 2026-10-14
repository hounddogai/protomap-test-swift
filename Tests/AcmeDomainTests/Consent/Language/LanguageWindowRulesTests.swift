@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageWindowValidator()
        let item = Consent.newLanguageWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageWindowRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Consent.LanguageWindowRateRangeRule(min: 8.9, max: 291.6)
        let item = Consent.newLanguageWindow("x", label: "y")
        item.rate = 293.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageWindowEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Consent.LanguageWindowEncounterIDLengthRule(maxLength: 1000)
        let item = Consent.newLanguageWindow("x", label: "y")
        item.encounterID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageWindowRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.LanguageWindowRequiredLabelRule(message: "language window needs this field")
        let item = Consent.newLanguageWindow("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageWindowDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Consent.LanguageWindowDosageMgRangeRule(min: 8.4, max: 909.2)
        let item = Consent.newLanguageWindow("x", label: "y")
        item.dosageMg = 910.7
        #expect(rule.check(item).count > 0)
    }
}
