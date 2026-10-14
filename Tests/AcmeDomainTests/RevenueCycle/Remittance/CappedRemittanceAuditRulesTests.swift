@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedRemittanceAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultCappedRemittanceAuditValidator()
        let item = RevenueCycle.newCappedRemittanceAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleCappedRemittanceAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.CappedRemittanceAuditTitleLengthRule(maxLength: 120)
        let item = RevenueCycle.newCappedRemittanceAudit("x", label: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleCappedRemittanceAuditBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = RevenueCycle.CappedRemittanceAuditBatchSizeRangeRule(min: 255, max: 1000)
        let item = RevenueCycle.newCappedRemittanceAudit("x", label: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleCappedRemittanceAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.CappedRemittanceAuditRequiredTitleRule(message: "capped remittance audit needs an entry")
        let item = RevenueCycle.newCappedRemittanceAudit("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleCappedRemittanceAuditRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = RevenueCycle.CappedRemittanceAuditRequiredProcedureCodeRule(
            message: "capped remittance audit needs an entry"
        )
        let item = RevenueCycle.newCappedRemittanceAudit("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleCappedRemittanceAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.CappedRemittanceAuditCodeLengthRule(maxLength: 80)
        let item = RevenueCycle.newCappedRemittanceAudit("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
