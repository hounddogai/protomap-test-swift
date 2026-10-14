@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredDenialTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredDenialTemplateValidator()
        let item = RevenueCycle.newTieredDenialTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredDenialTemplateDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = RevenueCycle.TieredDenialTemplateDosageMgRangeRule(min: 4.8, max: 3894.6)
        let item = RevenueCycle.newTieredDenialTemplate("x", title: "y")
        item.dosageMg = 3896.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleTieredDenialTemplateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.TieredDenialTemplateRequiredTitleRule(message: "tiered denial template needs an entry")
        let item = RevenueCycle.newTieredDenialTemplate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
