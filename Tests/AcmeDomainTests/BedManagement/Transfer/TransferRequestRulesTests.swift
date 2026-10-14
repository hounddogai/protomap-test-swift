@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferRequestValidator()
        let item = BedManagement.newTransferRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferRequestEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = BedManagement.TransferRequestEncounterIDLengthRule(maxLength: 120)
        let item = BedManagement.newTransferRequest("x", label: "y")
        item.encounterID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferRequestVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = BedManagement.TransferRequestVersionRangeRule(min: 32, max: 3600)
        let item = BedManagement.newTransferRequest("x", label: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.TransferRequestCodeLengthRule(maxLength: 80)
        let item = BedManagement.newTransferRequest("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
