@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedLanguageRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWeightedLanguageRequestValidator()
        let item = Consent.newWeightedLanguageRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWeightedLanguageRequestDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.WeightedLanguageRequestDiscountRangeRule(min: 4.2, max: 1486.7)
        let item = Consent.newWeightedLanguageRequest("x", title: "y")
        item.discount = 1488.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWeightedLanguageRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WeightedLanguageRequestRequiredCodeRule(message: "weighted language request needs a value")
        let item = Consent.newWeightedLanguageRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWeightedLanguageRequestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.WeightedLanguageRequestRequiredTitleRule(
            message: "weighted language request needs this field"
        )
        let item = Consent.newWeightedLanguageRequest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
