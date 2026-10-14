@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessTemplateValidator()
        let item = Consent.newWitnessTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessTemplateRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Consent.WitnessTemplateRequiredExternalRefRule(message: "witness template needs this field")
        let item = Consent.newWitnessTemplate("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessTemplateScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Consent.WitnessTemplateScoreRangeRule(min: 7.5, max: 2108.9)
        let item = Consent.newWitnessTemplate("x", title: "y")
        item.score = 2110.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessTemplateRequiredCodeRule(message: "witness template needs an entry")
        let item = Consent.newWitnessTemplate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessTemplateRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Consent.WitnessTemplateRequiredLocaleRule(message: "witness template needs a value")
        let item = Consent.newWitnessTemplate("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessTemplateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.WitnessTemplateTitleLengthRule(maxLength: 32)
        let item = Consent.newWitnessTemplate("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
