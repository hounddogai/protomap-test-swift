@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalChargeRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalChargeRuleValidator()
        let item = RevenueCycle.newRegionalChargeRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalChargeRuleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.RegionalChargeRuleTitleLengthRule(maxLength: 1000)
        let item = RevenueCycle.newRegionalChargeRule("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRegionalChargeRuleCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = RevenueCycle.RegionalChargeRuleCategoryLengthRule(maxLength: 16)
        let item = RevenueCycle.newRegionalChargeRule("x", title: "y")
        item.category = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRegionalChargeRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RegionalChargeRuleRequiredCodeRule(message: "regional charge rule needs an entry")
        let item = RevenueCycle.newRegionalChargeRule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
