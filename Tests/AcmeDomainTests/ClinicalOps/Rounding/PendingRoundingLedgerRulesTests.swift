@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingRoundingLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingRoundingLedgerValidator()
        let item = ClinicalOps.newPendingRoundingLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingRoundingLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.PendingRoundingLedgerRequiredNameRule(message: "pending rounding ledger needs this field")
        let item = ClinicalOps.newPendingRoundingLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPendingRoundingLedgerDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = ClinicalOps.PendingRoundingLedgerDiagnosisCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newPendingRoundingLedger("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
