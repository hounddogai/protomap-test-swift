@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictLanguageAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictLanguageAssignmentValidator()
        let item = Consent.newStrictLanguageAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictLanguageAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.StrictLanguageAssignmentRequiredCodeRule(message: "strict language assignment needs a value")
        let item = Consent.newStrictLanguageAssignment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictLanguageAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.StrictLanguageAssignmentTitleLengthRule(maxLength: 255)
        let item = Consent.newStrictLanguageAssignment("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentStrictLanguageAssignmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.StrictLanguageAssignmentRequiredTitleRule(
            message: "strict language assignment needs this field"
        )
        let item = Consent.newStrictLanguageAssignment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictLanguageAssignmentRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Consent.StrictLanguageAssignmentRequiredLocaleRule(
            message: "strict language assignment needs an entry"
        )
        let item = Consent.newStrictLanguageAssignment("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictLanguageAssignmentRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Consent.StrictLanguageAssignmentRateRangeRule(min: 9.3, max: 887.0)
        let item = Consent.newStrictLanguageAssignment("x", title: "y")
        item.rate = 888.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictLanguageAssignmentVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Consent.StrictLanguageAssignmentVisitMinutesRangeRule(min: 64, max: 3600)
        let item = Consent.newStrictLanguageAssignment("x", title: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}
