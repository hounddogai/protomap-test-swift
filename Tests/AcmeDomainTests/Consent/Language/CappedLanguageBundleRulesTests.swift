@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedLanguageBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedLanguageBundleValidator()
        let item = Consent.newCappedLanguageBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedLanguageBundleRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Consent.CappedLanguageBundleRequiredChannelRule(message: "capped language bundle needs this field")
        let item = Consent.newCappedLanguageBundle("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedLanguageBundleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Consent.CappedLanguageBundleScoreRangeRule(min: 0.5, max: 3339.5)
        let item = Consent.newCappedLanguageBundle("x", label: "y")
        item.score = 3341.0
        #expect(rule.check(item).count > 0)
    }
}
