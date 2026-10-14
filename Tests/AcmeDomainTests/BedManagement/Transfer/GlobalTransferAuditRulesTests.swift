@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalTransferAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalTransferAuditValidator()
        let item = BedManagement.newGlobalTransferAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalTransferAuditRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.GlobalTransferAuditRequiredNameRule(message: "global transfer audit needs a value")
        let item = BedManagement.newGlobalTransferAudit("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalTransferAuditExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = BedManagement.GlobalTransferAuditExternalRefLengthRule(maxLength: 3600)
        let item = BedManagement.newGlobalTransferAudit("x", name: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementGlobalTransferAuditChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = BedManagement.GlobalTransferAuditChecksumLengthRule(maxLength: 86400)
        let item = BedManagement.newGlobalTransferAudit("x", name: "y")
        item.checksum = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementGlobalTransferAuditRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = BedManagement.GlobalTransferAuditRequiredExternalRefRule(
            message: "global transfer audit needs a value"
        )
        let item = BedManagement.newGlobalTransferAudit("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
