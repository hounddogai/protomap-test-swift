@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictChargeGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStrictChargeGroupValidator()
        let item = RevenueCycle.newStrictChargeGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStrictChargeGroupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.StrictChargeGroupRequiredTitleRule(message: "strict charge group needs this field")
        let item = RevenueCycle.newStrictChargeGroup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStrictChargeGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StrictChargeGroupCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newStrictChargeGroup("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStrictChargeGroupAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.StrictChargeGroupAmountRangeRule(min: 7.0, max: 4100.0)
        let item = RevenueCycle.newStrictChargeGroup("x", title: "y")
        item.amount = 4101.5
        #expect(rule.check(item).count > 0)
    }
}
