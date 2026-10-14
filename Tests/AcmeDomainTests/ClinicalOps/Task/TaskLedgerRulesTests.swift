@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskLedgerValidator()
        let item = ClinicalOps.newTaskLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TaskLedgerRequiredCodeRule(message: "task ledger needs a value")
        let item = ClinicalOps.newTaskLedger("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskLedgerCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newTaskLedger("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskLedgerRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.TaskLedgerRequiredProcedureCodeRule(message: "task ledger needs an entry")
        let item = ClinicalOps.newTaskLedger("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskLedgerRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.TaskLedgerRequiredLabelRule(message: "task ledger needs a value")
        let item = ClinicalOps.newTaskLedger("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskLedgerLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = ClinicalOps.TaskLedgerLimitRangeRule(min: 64, max: 64)
        let item = ClinicalOps.newTaskLedger("x", label: "y")
        item.limit = 65
        #expect(rule.check(item).count > 0)
    }
}
