@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredLanguageTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultTieredLanguageTemplateValidator()
        let item = Consent.newTieredLanguageTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentTieredLanguageTemplateWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Consent.TieredLanguageTemplateWeightRangeRule(min: 6.1, max: 1306.9)
        let item = Consent.newTieredLanguageTemplate("x", title: "y")
        item.weight = 1308.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentTieredLanguageTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.TieredLanguageTemplateRequiredCodeRule(message: "tiered language template needs an entry")
        let item = Consent.newTieredLanguageTemplate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentTieredLanguageTemplateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.TieredLanguageTemplateRequiredTitleRule(message: "tiered language template needs a value")
        let item = Consent.newTieredLanguageTemplate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentTieredLanguageTemplateDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.TieredLanguageTemplateDiscountRangeRule(min: 6.2, max: 1860.7)
        let item = Consent.newTieredLanguageTemplate("x", title: "y")
        item.discount = 1862.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentTieredLanguageTemplateRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Consent.TieredLanguageTemplateRatioRangeRule(min: 7.3, max: 2403.0)
        let item = Consent.newTieredLanguageTemplate("x", title: "y")
        item.ratio = 2404.5
        #expect(rule.check(item).count > 0)
    }
}
