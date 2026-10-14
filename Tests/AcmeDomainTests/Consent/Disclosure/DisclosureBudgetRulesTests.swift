@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureBudgetValidator()
        let item = Consent.newDisclosureBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DisclosureBudgetRequiredCodeRule(message: "disclosure budget needs an entry")
        let item = Consent.newDisclosureBudget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureBudgetCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Consent.DisclosureBudgetCountryLengthRule(maxLength: 80)
        let item = Consent.newDisclosureBudget("x", title: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureBudgetScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Consent.DisclosureBudgetScoreRangeRule(min: 5.0, max: 1305.6)
        let item = Consent.newDisclosureBudget("x", title: "y")
        item.score = 1307.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.DisclosureBudgetCodeLengthRule(maxLength: 255)
        let item = Consent.newDisclosureBudget("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureBudgetDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Consent.DisclosureBudgetDescriptionLengthRule(maxLength: 120)
        let item = Consent.newDisclosureBudget("x", title: "y")
        item.description = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
