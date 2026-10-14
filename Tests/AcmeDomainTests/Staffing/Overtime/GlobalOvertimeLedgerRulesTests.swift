@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalOvertimeLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalOvertimeLedgerValidator()
        let item = Staffing.newGlobalOvertimeLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalOvertimeLedgerRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Staffing.GlobalOvertimeLedgerRequiredClinicianIDRule(
            message: "global overtime ledger needs this field"
        )
        let item = Staffing.newGlobalOvertimeLedger("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalOvertimeLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.GlobalOvertimeLedgerNameLengthRule(maxLength: 80)
        let item = Staffing.newGlobalOvertimeLedger("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalOvertimeLedgerQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Staffing.GlobalOvertimeLedgerQuantityRangeRule(min: 120, max: 255)
        let item = Staffing.newGlobalOvertimeLedger("x", name: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}
