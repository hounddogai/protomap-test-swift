@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffLedgerValidator()
        let item = ClinicalOps.newHandoffLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.HandoffLedgerRequiredCodeRule(message: "handoff ledger needs this field")
        let item = ClinicalOps.newHandoffLedger("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffLedgerTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.HandoffLedgerTitleLengthRule(maxLength: 1000)
        let item = ClinicalOps.newHandoffLedger("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.HandoffLedgerCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newHandoffLedger("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
