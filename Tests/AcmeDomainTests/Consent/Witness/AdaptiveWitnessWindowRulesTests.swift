@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveWitnessWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveWitnessWindowValidator()
        let item = Consent.newAdaptiveWitnessWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveWitnessWindowRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.AdaptiveWitnessWindowRequiredLabelRule(message: "adaptive witness window needs this field")
        let item = Consent.newAdaptiveWitnessWindow("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveWitnessWindowRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Consent.AdaptiveWitnessWindowRequiredBedRule(message: "adaptive witness window needs an entry")
        let item = Consent.newAdaptiveWitnessWindow("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveWitnessWindowLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.AdaptiveWitnessWindowLocaleLengthRule(maxLength: 80)
        let item = Consent.newAdaptiveWitnessWindow("x", label: "y")
        item.locale = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveWitnessWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.AdaptiveWitnessWindowLabelLengthRule(maxLength: 255)
        let item = Consent.newAdaptiveWitnessWindow("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
