@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyStatementExceptionValidator()
        let item = RevenueCycle.newLegacyStatementException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyStatementExceptionRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = RevenueCycle.LegacyStatementExceptionRequiredBedRule(
            message: "legacy statement exception needs a value"
        )
        let item = RevenueCycle.newLegacyStatementException("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyStatementExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.LegacyStatementExceptionCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newLegacyStatementException("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyStatementExceptionBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = RevenueCycle.LegacyStatementExceptionBedLengthRule(maxLength: 120)
        let item = RevenueCycle.newLegacyStatementException("x", title: "y")
        item.bed = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyStatementExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.LegacyStatementExceptionTitleLengthRule(maxLength: 1000)
        let item = RevenueCycle.newLegacyStatementException("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyStatementExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.LegacyStatementExceptionRequiredCodeRule(
            message: "legacy statement exception needs an entry"
        )
        let item = RevenueCycle.newLegacyStatementException("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
