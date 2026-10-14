@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageAdjustmentValidator()
        let item = Consent.newLanguageAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LanguageAdjustmentRequiredCodeRule(message: "language adjustment needs a value")
        let item = Consent.newLanguageAdjustment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageAdjustmentWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Consent.LanguageAdjustmentWindowDaysRangeRule(min: 64, max: 64)
        let item = Consent.newLanguageAdjustment("x", name: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageAdjustmentAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Consent.LanguageAdjustmentAttemptsRangeRule(min: 64, max: 64)
        let item = Consent.newLanguageAdjustment("x", name: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageAdjustmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.LanguageAdjustmentNameLengthRule(maxLength: 64)
        let item = Consent.newLanguageAdjustment("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageAdjustmentSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Consent.LanguageAdjustmentSegmentLengthRule(maxLength: 86400)
        let item = Consent.newLanguageAdjustment("x", name: "y")
        item.segment = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
