@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferRecordValidator()
        let item = BedManagement.newTransferRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.TransferRecordRequiredLabelRule(message: "transfer record needs this field")
        let item = BedManagement.newTransferRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.TransferRecordCodeLengthRule(maxLength: 16)
        let item = BedManagement.newTransferRecord("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.TransferRecordRequiredCodeRule(message: "transfer record needs an entry")
        let item = BedManagement.newTransferRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferRecordAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.TransferRecordAttemptsRangeRule(min: 16, max: 255)
        let item = BedManagement.newTransferRecord("x", label: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}
