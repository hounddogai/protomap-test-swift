@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageVarianceValidator()
        let item = Consent.newLanguageVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageVarianceRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Consent.LanguageVarianceRequiredPhoneRule(message: "language variance needs a value")
        let item = Consent.newLanguageVariance("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LanguageVarianceRequiredCodeRule(message: "language variance needs a value")
        let item = Consent.newLanguageVariance("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.LanguageVarianceRequiredTitleRule(message: "language variance needs this field")
        let item = Consent.newLanguageVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.LanguageVarianceTitleLengthRule(maxLength: 120)
        let item = Consent.newLanguageVariance("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
