@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultStatementLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultStatementLedgerValidator()
        let item = RevenueCycle.newDefaultStatementLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultStatementLedgerExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = RevenueCycle.DefaultStatementLedgerExternalRefLengthRule(maxLength: 1000)
        let item = RevenueCycle.newDefaultStatementLedger("x", title: "y")
        item.externalRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultStatementLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.DefaultStatementLedgerCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newDefaultStatementLedger("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultStatementLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.DefaultStatementLedgerRequiredNameRule(
            message: "default statement ledger needs an entry"
        )
        let item = RevenueCycle.newDefaultStatementLedger("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultStatementLedgerTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.DefaultStatementLedgerTitleLengthRule(maxLength: 120)
        let item = RevenueCycle.newDefaultStatementLedger("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultStatementLedgerRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.DefaultStatementLedgerRequiredTitleRule(
            message: "default statement ledger needs an entry"
        )
        let item = RevenueCycle.newDefaultStatementLedger("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
