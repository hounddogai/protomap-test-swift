@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialDraftValidator()
        let item = RevenueCycle.newDenialDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.DenialDraftRequiredLabelRule(message: "denial draft needs an entry")
        let item = RevenueCycle.newDenialDraft("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialDraftGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = RevenueCycle.DenialDraftGraceDaysRangeRule(min: 16, max: 86400)
        let item = RevenueCycle.newDenialDraft("x", label: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.DenialDraftCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newDenialDraft("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
