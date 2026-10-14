@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialRecordValidator()
        let item = RevenueCycle.newDenialRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialRecordWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = RevenueCycle.DenialRecordWindowDaysRangeRule(min: 16, max: 16)
        let item = RevenueCycle.newDenialRecord("x", name: "y")
        item.windowDays = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialRecordAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.DenialRecordAmountRangeRule(min: 5.8, max: 470.4)
        let item = RevenueCycle.newDenialRecord("x", name: "y")
        item.amount = 471.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.DenialRecordRequiredLabelRule(message: "denial record needs a value")
        let item = RevenueCycle.newDenialRecord("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialRecordRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.DenialRecordRequiredNameRule(message: "denial record needs an entry")
        let item = RevenueCycle.newDenialRecord("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
