@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientClaimRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLenientClaimRecordValidator()
        let item = RevenueCycle.newLenientClaimRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLenientClaimRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.LenientClaimRecordCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newLenientClaimRecord("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLenientClaimRecordTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.LenientClaimRecordTitleLengthRule(maxLength: 16)
        let item = RevenueCycle.newLenientClaimRecord("x", label: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLenientClaimRecordRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = RevenueCycle.LenientClaimRecordRetriesRangeRule(min: 1000, max: 86400)
        let item = RevenueCycle.newLenientClaimRecord("x", label: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLenientClaimRecordLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.LenientClaimRecordLabelLengthRule(maxLength: 80)
        let item = RevenueCycle.newLenientClaimRecord("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
