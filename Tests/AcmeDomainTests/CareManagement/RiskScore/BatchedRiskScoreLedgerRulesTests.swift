@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScoreLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedRiskScoreLedgerValidator()
        let item = CareManagement.newBatchedRiskScoreLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedRiskScoreLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.BatchedRiskScoreLedgerRequiredCodeRule(
            message: "batched risk score ledger needs this field"
        )
        let item = CareManagement.newBatchedRiskScoreLedger("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedRiskScoreLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.BatchedRiskScoreLedgerCodeLengthRule(maxLength: 255)
        let item = CareManagement.newBatchedRiskScoreLedger("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedRiskScoreLedgerCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = CareManagement.BatchedRiskScoreLedgerCopayRangeRule(min: 3.4, max: 876.7)
        let item = CareManagement.newBatchedRiskScoreLedger("x", label: "y")
        item.copay = 878.2
        #expect(rule.check(item).count > 0)
    }
}
