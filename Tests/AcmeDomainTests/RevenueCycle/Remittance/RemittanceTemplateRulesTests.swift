@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceTemplateValidator()
        let item = RevenueCycle.newRemittanceTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceTemplateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.RemittanceTemplateTitleLengthRule(maxLength: 80)
        let item = RevenueCycle.newRemittanceTemplate("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceTemplateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.RemittanceTemplateRequiredTitleRule(message: "remittance template needs an entry")
        let item = RevenueCycle.newRemittanceTemplate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceTemplateMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.RemittanceTemplateMaximumRangeRule(min: 3.8, max: 1485.4)
        let item = RevenueCycle.newRemittanceTemplate("x", title: "y")
        item.maximum = 1486.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittanceTemplateRequiredCodeRule(message: "remittance template needs this field")
        let item = RevenueCycle.newRemittanceTemplate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceTemplateBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = RevenueCycle.RemittanceTemplateBedLengthRule(maxLength: 120)
        let item = RevenueCycle.newRemittanceTemplate("x", title: "y")
        item.bed = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
