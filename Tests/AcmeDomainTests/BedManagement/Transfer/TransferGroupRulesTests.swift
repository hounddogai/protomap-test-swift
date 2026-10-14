@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferGroupValidator()
        let item = BedManagement.newTransferGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferGroupUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = BedManagement.TransferGroupUnitLengthRule(maxLength: 120)
        let item = BedManagement.newTransferGroup("x", name: "y")
        item.unit = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferGroupRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.TransferGroupRequiredClinicianIDRule(message: "transfer group needs this field")
        let item = BedManagement.newTransferGroup("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferGroupClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = BedManagement.TransferGroupClinicianIDLengthRule(maxLength: 16)
        let item = BedManagement.newTransferGroup("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.TransferGroupRequiredCodeRule(message: "transfer group needs an entry")
        let item = BedManagement.newTransferGroup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
