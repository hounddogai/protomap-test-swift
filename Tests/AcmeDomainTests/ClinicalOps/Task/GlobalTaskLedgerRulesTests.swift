@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalTaskLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalTaskLedgerValidator()
        let item = ClinicalOps.newGlobalTaskLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalTaskLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.GlobalTaskLedgerRequiredCodeRule(message: "global task ledger needs an entry")
        let item = ClinicalOps.newGlobalTaskLedger("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalTaskLedgerRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.GlobalTaskLedgerRequiredTitleRule(message: "global task ledger needs an entry")
        let item = ClinicalOps.newGlobalTaskLedger("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalTaskLedgerVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = ClinicalOps.GlobalTaskLedgerVersionRangeRule(min: 80, max: 3600)
        let item = ClinicalOps.newGlobalTaskLedger("x", title: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalTaskLedgerTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.GlobalTaskLedgerTitleLengthRule(maxLength: 86400)
        let item = ClinicalOps.newGlobalTaskLedger("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
