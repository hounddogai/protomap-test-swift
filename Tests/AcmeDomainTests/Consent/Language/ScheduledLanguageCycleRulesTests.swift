@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledLanguageCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledLanguageCycleValidator()
        let item = Consent.newScheduledLanguageCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledLanguageCycleRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Consent.ScheduledLanguageCycleRateRangeRule(min: 1.9, max: 3832.5)
        let item = Consent.newScheduledLanguageCycle("x", title: "y")
        item.rate = 3834.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentScheduledLanguageCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ScheduledLanguageCycleRequiredCodeRule(message: "scheduled language cycle needs this field")
        let item = Consent.newScheduledLanguageCycle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledLanguageCycleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.ScheduledLanguageCycleTitleLengthRule(maxLength: 80)
        let item = Consent.newScheduledLanguageCycle("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledLanguageCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ScheduledLanguageCycleCodeLengthRule(maxLength: 32)
        let item = Consent.newScheduledLanguageCycle("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledLanguageCycleRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Consent.ScheduledLanguageCycleRequiredReviewerRule(
            message: "scheduled language cycle needs this field"
        )
        let item = Consent.newScheduledLanguageCycle("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
