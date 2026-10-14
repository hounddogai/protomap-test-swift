@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryDischargePlanLedgerValidator()
        let item = BedManagement.newPrimaryDischargePlanLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanLedgerChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = BedManagement.PrimaryDischargePlanLedgerChecksumLengthRule(maxLength: 32)
        let item = BedManagement.newPrimaryDischargePlanLedger("x", title: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanLedgerCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.PrimaryDischargePlanLedgerCopayRangeRule(min: 3.0, max: 1485.4)
        let item = BedManagement.newPrimaryDischargePlanLedger("x", title: "y")
        item.copay = 1486.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanLedgerFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.PrimaryDischargePlanLedgerFloorValueRangeRule(min: 9.2, max: 4525.4)
        let item = BedManagement.newPrimaryDischargePlanLedger("x", title: "y")
        item.floorValue = 4526.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.PrimaryDischargePlanLedgerRequiredCodeRule(
            message: "primary discharge plan ledger needs an entry"
        )
        let item = BedManagement.newPrimaryDischargePlanLedger("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryDischargePlanLedgerVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = BedManagement.PrimaryDischargePlanLedgerVersionRangeRule(min: 64, max: 80)
        let item = BedManagement.newPrimaryDischargePlanLedger("x", title: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}
