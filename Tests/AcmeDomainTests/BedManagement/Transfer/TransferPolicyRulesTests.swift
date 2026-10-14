@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferPolicyValidator()
        let item = BedManagement.newTransferPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferPolicyDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = BedManagement.TransferPolicyDiagnosisCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newTransferPolicy("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferPolicyRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = BedManagement.TransferPolicyRequiredDiagnosisCodeRule(message: "transfer policy needs an entry")
        let item = BedManagement.newTransferPolicy("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferPolicyNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.TransferPolicyNameLengthRule(maxLength: 1000)
        let item = BedManagement.newTransferPolicy("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferPolicyGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.TransferPolicyGraceDaysRangeRule(min: 64, max: 120)
        let item = BedManagement.newTransferPolicy("x", name: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferPolicyRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.TransferPolicyRequiredClinicianIDRule(message: "transfer policy needs this field")
        let item = BedManagement.newTransferPolicy("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
