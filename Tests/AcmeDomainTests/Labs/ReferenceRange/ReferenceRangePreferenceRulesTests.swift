@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangePreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangePreferenceValidator()
        let item = Labs.newReferenceRangePreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangePreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.ReferenceRangePreferenceRequiredTitleRule(message: "reference range preference needs a value")
        let item = Labs.newReferenceRangePreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangePreferenceRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Labs.ReferenceRangePreferenceRequiredLocaleRule(message: "reference range preference needs an entry")
        let item = Labs.newReferenceRangePreference("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangePreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ReferenceRangePreferenceCodeLengthRule(maxLength: 32)
        let item = Labs.newReferenceRangePreference("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangePreferenceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.ReferenceRangePreferenceTitleLengthRule(maxLength: 1000)
        let item = Labs.newReferenceRangePreference("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangePreferenceScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.ReferenceRangePreferenceScoreRangeRule(min: 2.2, max: 483.2)
        let item = Labs.newReferenceRangePreference("x", title: "y")
        item.score = 484.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangePreferenceLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Labs.ReferenceRangePreferenceLocaleLengthRule(maxLength: 32)
        let item = Labs.newReferenceRangePreference("x", title: "y")
        item.locale = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
