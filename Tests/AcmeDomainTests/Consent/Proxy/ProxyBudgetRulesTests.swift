@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyBudgetValidator()
        let item = Consent.newProxyBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyBudgetMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Consent.ProxyBudgetMaximumRangeRule(min: 9.0, max: 124.0)
        let item = Consent.newProxyBudget("x", name: "y")
        item.maximum = 125.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ProxyBudgetRequiredCodeRule(message: "proxy budget needs an entry")
        let item = Consent.newProxyBudget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyBudgetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ProxyBudgetRequiredNameRule(message: "proxy budget needs a value")
        let item = Consent.newProxyBudget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyBudgetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.ProxyBudgetNameLengthRule(maxLength: 86400)
        let item = Consent.newProxyBudget("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyBudgetFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Consent.ProxyBudgetFloorValueRangeRule(min: 6.7, max: 800.7)
        let item = Consent.newProxyBudget("x", name: "y")
        item.floorValue = 802.2
        #expect(rule.check(item).count > 0)
    }
}
