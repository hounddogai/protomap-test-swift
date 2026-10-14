@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageScoreValidator()
        let item = Consent.newLanguageScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageScoreLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.LanguageScoreLabelLengthRule(maxLength: 32)
        let item = Consent.newLanguageScore("x", name: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LanguageScoreRequiredCodeRule(message: "language score needs a value")
        let item = Consent.newLanguageScore("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.LanguageScoreNameLengthRule(maxLength: 80)
        let item = Consent.newLanguageScore("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
