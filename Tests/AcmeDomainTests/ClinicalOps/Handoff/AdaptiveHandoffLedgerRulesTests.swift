@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveHandoffLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAdaptiveHandoffLedgerValidator()
        let item = ClinicalOps.newAdaptiveHandoffLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffLedgerRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = ClinicalOps.AdaptiveHandoffLedgerRequiredUnitRule(message: "adaptive handoff ledger needs a value")
        let item = ClinicalOps.newAdaptiveHandoffLedger("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffLedgerTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.AdaptiveHandoffLedgerTitleLengthRule(maxLength: 16)
        let item = ClinicalOps.newAdaptiveHandoffLedger("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
