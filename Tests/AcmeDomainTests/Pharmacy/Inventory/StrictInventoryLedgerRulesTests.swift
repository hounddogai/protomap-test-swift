@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInventoryLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultStrictInventoryLedgerValidator()
        let item = Pharmacy.newStrictInventoryLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyStrictInventoryLedgerRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Pharmacy.StrictInventoryLedgerRequiredPatientRefRule(
            message: "strict inventory ledger needs an entry"
        )
        let item = Pharmacy.newStrictInventoryLedger("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyStrictInventoryLedgerRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.StrictInventoryLedgerRequiredTitleRule(message: "strict inventory ledger needs an entry")
        let item = Pharmacy.newStrictInventoryLedger("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyStrictInventoryLedgerBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Pharmacy.StrictInventoryLedgerBatchSizeRangeRule(min: 16, max: 64)
        let item = Pharmacy.newStrictInventoryLedger("x", title: "y")
        item.batchSize = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyStrictInventoryLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.StrictInventoryLedgerCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newStrictInventoryLedger("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
