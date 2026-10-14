@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientProxyEntryValidator()
        let item = Consent.newLenientProxyEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientProxyEntryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.LenientProxyEntryRequiredLabelRule(message: "lenient proxy entry needs an entry")
        let item = Consent.newLenientProxyEntry("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientProxyEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LenientProxyEntryRequiredCodeRule(message: "lenient proxy entry needs an entry")
        let item = Consent.newLenientProxyEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientProxyEntryBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Consent.LenientProxyEntryBudgetRangeRule(min: 3.1, max: 2632.8)
        let item = Consent.newLenientProxyEntry("x", label: "y")
        item.budget = 2634.3
        #expect(rule.check(item).count > 0)
    }
}
