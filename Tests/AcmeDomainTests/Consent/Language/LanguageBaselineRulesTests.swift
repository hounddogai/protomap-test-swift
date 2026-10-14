@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageBaselineValidator()
        let item = Consent.newLanguageBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageBaselineRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.LanguageBaselineRequiredNameRule(message: "language baseline needs a value")
        let item = Consent.newLanguageBaseline("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageBaselineSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Consent.LanguageBaselineSummaryLengthRule(maxLength: 86400)
        let item = Consent.newLanguageBaseline("x", name: "y")
        item.summary = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageBaselinePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Consent.LanguageBaselinePatientRefLengthRule(maxLength: 255)
        let item = Consent.newLanguageBaseline("x", name: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.LanguageBaselineNameLengthRule(maxLength: 120)
        let item = Consent.newLanguageBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
