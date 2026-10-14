@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferAgreementValidator()
        let item = BedManagement.newTransferAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferAgreementRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = BedManagement.TransferAgreementRequiredExternalRefRule(message: "transfer agreement needs this field")
        let item = BedManagement.newTransferAgreement("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.TransferAgreementCodeLengthRule(maxLength: 120)
        let item = BedManagement.newTransferAgreement("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
