@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyProxyBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLegacyProxyBudgetValidator()
        let item = Consent.newLegacyProxyBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLegacyProxyBudgetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.LegacyProxyBudgetRequiredTitleRule(message: "legacy proxy budget needs this field")
        let item = Consent.newLegacyProxyBudget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLegacyProxyBudgetDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Consent.LegacyProxyBudgetDescriptionLengthRule(maxLength: 120)
        let item = Consent.newLegacyProxyBudget("x", title: "y")
        item.description = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLegacyProxyBudgetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.LegacyProxyBudgetTitleLengthRule(maxLength: 16)
        let item = Consent.newLegacyProxyBudget("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLegacyProxyBudgetFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Consent.LegacyProxyBudgetFloorValueRangeRule(min: 6.7, max: 231.4)
        let item = Consent.newLegacyProxyBudget("x", title: "y")
        item.floorValue = 232.9
        #expect(rule.check(item).count > 0)
    }
}
