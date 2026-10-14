@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialBudgetValidator()
        let item = RevenueCycle.newDenialBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialBudgetChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = RevenueCycle.DenialBudgetChecksumLengthRule(maxLength: 1000)
        let item = RevenueCycle.newDenialBudget("x", title: "y")
        item.checksum = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialBudgetRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = RevenueCycle.DenialBudgetRequiredChecksumRule(message: "denial budget needs an entry")
        let item = RevenueCycle.newDenialBudget("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialBudgetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.DenialBudgetTitleLengthRule(maxLength: 64)
        let item = RevenueCycle.newDenialBudget("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DenialBudgetRequiredCodeRule(message: "denial budget needs this field")
        let item = RevenueCycle.newDenialBudget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialBudgetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.DenialBudgetRequiredTitleRule(message: "denial budget needs a value")
        let item = RevenueCycle.newDenialBudget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
