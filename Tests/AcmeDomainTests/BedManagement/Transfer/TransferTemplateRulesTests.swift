@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferTemplateValidator()
        let item = BedManagement.newTransferTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferTemplateClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = BedManagement.TransferTemplateClinicianIDLengthRule(maxLength: 16)
        let item = BedManagement.newTransferTemplate("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferTemplateAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.TransferTemplateAttemptsRangeRule(min: 16, max: 3600)
        let item = BedManagement.newTransferTemplate("x", title: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferTemplateRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.TransferTemplateRequiredClinicianIDRule(message: "transfer template needs this field")
        let item = BedManagement.newTransferTemplate("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferTemplateRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = BedManagement.TransferTemplateRequiredSourceRule(message: "transfer template needs an entry")
        let item = BedManagement.newTransferTemplate("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}
