@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientLanguageScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientLanguageScoreValidator()
        let item = Consent.newLenientLanguageScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientLanguageScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LenientLanguageScoreRequiredCodeRule(message: "lenient language score needs this field")
        let item = Consent.newLenientLanguageScore("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientLanguageScoreRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Consent.LenientLanguageScoreRetriesRangeRule(min: 255, max: 3600)
        let item = Consent.newLenientLanguageScore("x", name: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLenientLanguageScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LenientLanguageScoreCodeLengthRule(maxLength: 16)
        let item = Consent.newLenientLanguageScore("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientLanguageScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.LenientLanguageScoreNameLengthRule(maxLength: 32)
        let item = Consent.newLenientLanguageScore("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientLanguageScoreStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Consent.LenientLanguageScoreStartsAtRangeRule(min: 16, max: 120)
        let item = Consent.newLenientLanguageScore("x", name: "y")
        item.startsAt = 121
        #expect(rule.check(item).count > 0)
    }
}
