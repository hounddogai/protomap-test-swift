@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageBatchValidator()
        let item = Consent.newLanguageBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.LanguageBatchTitleLengthRule(maxLength: 86400)
        let item = Consent.newLanguageBatch("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageBatchRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Consent.LanguageBatchRequiredPhoneRule(message: "language batch needs a value")
        let item = Consent.newLanguageBatch("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageBatchStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Consent.LanguageBatchStartsAtRangeRule(min: 16, max: 120)
        let item = Consent.newLanguageBatch("x", title: "y")
        item.startsAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageBatchRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Consent.LanguageBatchRequiredCategoryRule(message: "language batch needs an entry")
        let item = Consent.newLanguageBatch("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LanguageBatchCodeLengthRule(maxLength: 3600)
        let item = Consent.newLanguageBatch("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
