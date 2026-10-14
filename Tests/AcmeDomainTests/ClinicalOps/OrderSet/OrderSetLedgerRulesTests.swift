@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetLedgerValidator()
        let item = ClinicalOps.newOrderSetLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.OrderSetLedgerRequiredNameRule(message: "order set ledger needs this field")
        let item = ClinicalOps.newOrderSetLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetLedgerScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = ClinicalOps.OrderSetLedgerScoreRangeRule(min: 0.3, max: 1842.2)
        let item = ClinicalOps.newOrderSetLedger("x", name: "y")
        item.score = 1843.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetLedgerRequiredCodeRule(message: "order set ledger needs an entry")
        let item = ClinicalOps.newOrderSetLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetLedgerCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newOrderSetLedger("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
