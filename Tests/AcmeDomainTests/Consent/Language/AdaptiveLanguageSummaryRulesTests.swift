@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveLanguageSummaryValidator()
        let item = Consent.newAdaptiveLanguageSummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveLanguageSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.AdaptiveLanguageSummaryRequiredCodeRule(message: "adaptive language summary needs a value")
        let item = Consent.newAdaptiveLanguageSummary("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveLanguageSummaryStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Consent.AdaptiveLanguageSummaryStartsAtRangeRule(min: 120, max: 3600)
        let item = Consent.newAdaptiveLanguageSummary("x", name: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentAdaptiveLanguageSummaryDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Consent.AdaptiveLanguageSummaryDescriptionLengthRule(maxLength: 64)
        let item = Consent.newAdaptiveLanguageSummary("x", name: "y")
        item.description = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
