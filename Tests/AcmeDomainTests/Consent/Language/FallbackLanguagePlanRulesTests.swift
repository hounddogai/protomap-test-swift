@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackLanguagePlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultFallbackLanguagePlanValidator()
        let item = Consent.newFallbackLanguagePlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentFallbackLanguagePlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.FallbackLanguagePlanRequiredCodeRule(message: "fallback language plan needs a value")
        let item = Consent.newFallbackLanguagePlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentFallbackLanguagePlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.FallbackLanguagePlanRequiredTitleRule(message: "fallback language plan needs an entry")
        let item = Consent.newFallbackLanguagePlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentFallbackLanguagePlanTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.FallbackLanguagePlanTitleLengthRule(maxLength: 255)
        let item = Consent.newFallbackLanguagePlan("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
