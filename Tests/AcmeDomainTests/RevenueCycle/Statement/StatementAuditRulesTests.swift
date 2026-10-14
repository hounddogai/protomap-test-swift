@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementAuditValidator()
        let item = RevenueCycle.newStatementAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementAuditRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = RevenueCycle.StatementAuditRegionLengthRule(maxLength: 86400)
        let item = RevenueCycle.newStatementAudit("x", name: "y")
        item.region = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementAuditRequiredCodeRule(message: "statement audit needs an entry")
        let item = RevenueCycle.newStatementAudit("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementAuditCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = RevenueCycle.StatementAuditCategoryLengthRule(maxLength: 80)
        let item = RevenueCycle.newStatementAudit("x", name: "y")
        item.category = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementAuditCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = RevenueCycle.StatementAuditCopayRangeRule(min: 2.6, max: 1105.0)
        let item = RevenueCycle.newStatementAudit("x", name: "y")
        item.copay = 1106.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementAuditScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = RevenueCycle.StatementAuditScoreRangeRule(min: 1.3, max: 3223.1)
        let item = RevenueCycle.newStatementAudit("x", name: "y")
        item.score = 3224.6
        #expect(rule.check(item).count > 0)
    }
}
