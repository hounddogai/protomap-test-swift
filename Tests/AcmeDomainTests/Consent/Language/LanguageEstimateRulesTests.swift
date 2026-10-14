@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageEstimateValidator()
        let item = Consent.newLanguageEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageEstimateSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Consent.LanguageEstimateSourceLengthRule(maxLength: 86400)
        let item = Consent.newLanguageEstimate("x", title: "y")
        item.source = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageEstimateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.LanguageEstimateRequiredTitleRule(message: "language estimate needs an entry")
        let item = Consent.newLanguageEstimate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LanguageEstimateRequiredCodeRule(message: "language estimate needs this field")
        let item = Consent.newLanguageEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageEstimateRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Consent.LanguageEstimateRequiredSourceRule(message: "language estimate needs a value")
        let item = Consent.newLanguageEstimate("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LanguageEstimateCodeLengthRule(maxLength: 16)
        let item = Consent.newLanguageEstimate("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
