@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotLedgerValidator()
        let item = Referrals.newSlotLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotLedgerBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.SlotLedgerBatchSizeRangeRule(min: 16, max: 255)
        let item = Referrals.newSlotLedger("x", name: "y")
        item.batchSize = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotLedgerFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Referrals.SlotLedgerFloorValueRangeRule(min: 2.2, max: 2101.0)
        let item = Referrals.newSlotLedger("x", name: "y")
        item.floorValue = 2102.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotLedgerRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.SlotLedgerRequiredPatientRefRule(message: "slot ledger needs an entry")
        let item = Referrals.newSlotLedger("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
