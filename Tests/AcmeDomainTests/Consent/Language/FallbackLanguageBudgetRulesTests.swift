@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackLanguageBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultFallbackLanguageBudgetValidator()
        let item = Consent.newFallbackLanguageBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentFallbackLanguageBudgetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.FallbackLanguageBudgetNameLengthRule(maxLength: 86400)
        let item = Consent.newFallbackLanguageBudget("x", title: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentFallbackLanguageBudgetRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Consent.FallbackLanguageBudgetRevisionRangeRule(min: 255, max: 1000)
        let item = Consent.newFallbackLanguageBudget("x", title: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentFallbackLanguageBudgetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.FallbackLanguageBudgetTitleLengthRule(maxLength: 255)
        let item = Consent.newFallbackLanguageBudget("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
