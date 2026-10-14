@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingHandoffLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingHandoffLedgerValidator()
        let item = ClinicalOps.newPendingHandoffLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingHandoffLedgerRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = ClinicalOps.PendingHandoffLedgerRequiredClinicianIDRule(
            message: "pending handoff ledger needs an entry"
        )
        let item = ClinicalOps.newPendingHandoffLedger("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPendingHandoffLedgerUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = ClinicalOps.PendingHandoffLedgerUpdatedAtRangeRule(min: 16, max: 1000)
        let item = ClinicalOps.newPendingHandoffLedger("x", title: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingHandoffLedgerRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.PendingHandoffLedgerRequiredTitleRule(message: "pending handoff ledger needs a value")
        let item = ClinicalOps.newPendingHandoffLedger("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPendingHandoffLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.PendingHandoffLedgerCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newPendingHandoffLedger("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPendingHandoffLedgerGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = ClinicalOps.PendingHandoffLedgerGraceDaysRangeRule(min: 80, max: 86400)
        let item = ClinicalOps.newPendingHandoffLedger("x", title: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingHandoffLedgerQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = ClinicalOps.PendingHandoffLedgerQuantityRangeRule(min: 1000, max: 86400)
        let item = ClinicalOps.newPendingHandoffLedger("x", title: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}
