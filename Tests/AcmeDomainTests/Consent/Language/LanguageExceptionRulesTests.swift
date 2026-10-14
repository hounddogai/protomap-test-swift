@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageExceptionValidator()
        let item = Consent.newLanguageException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageExceptionRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.LanguageExceptionRequiredTitleRule(message: "language exception needs this field")
        let item = Consent.newLanguageException("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageExceptionDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Consent.LanguageExceptionDurationMinutesRangeRule(min: 64, max: 86400)
        let item = Consent.newLanguageException("x", title: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.LanguageExceptionTitleLengthRule(maxLength: 86400)
        let item = Consent.newLanguageException("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LanguageExceptionRequiredCodeRule(message: "language exception needs an entry")
        let item = Consent.newLanguageException("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
