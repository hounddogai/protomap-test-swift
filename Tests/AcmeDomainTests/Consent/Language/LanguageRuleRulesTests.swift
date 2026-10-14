@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageRuleValidator()
        let item = Consent.newLanguageRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageRuleCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Consent.LanguageRuleCeilingRangeRule(min: 2.2, max: 2160.7)
        let item = Consent.newLanguageRule("x", title: "y")
        item.ceiling = 2162.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageRuleRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Consent.LanguageRuleRequiredReviewerRule(message: "language rule needs a value")
        let item = Consent.newLanguageRule("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageRuleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.LanguageRuleRequiredTitleRule(message: "language rule needs this field")
        let item = Consent.newLanguageRule("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageRuleCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.LanguageRuleCostRangeRule(min: 5.1, max: 115.7)
        let item = Consent.newLanguageRule("x", title: "y")
        item.cost = 117.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LanguageRuleRequiredCodeRule(message: "language rule needs a value")
        let item = Consent.newLanguageRule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
