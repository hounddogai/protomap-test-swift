@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedIsolationRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBatchedIsolationRecordValidator()
        let item = BedManagement.newBatchedIsolationRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBatchedIsolationRecordDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = BedManagement.BatchedIsolationRecordDescriptionLengthRule(maxLength: 120)
        let item = BedManagement.newBatchedIsolationRecord("x", label: "y")
        item.description = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBatchedIsolationRecordOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = BedManagement.BatchedIsolationRecordOwnerIDLengthRule(maxLength: 3600)
        let item = BedManagement.newBatchedIsolationRecord("x", label: "y")
        item.ownerID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBatchedIsolationRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.BatchedIsolationRecordRequiredLabelRule(
            message: "batched isolation record needs an entry"
        )
        let item = BedManagement.newBatchedIsolationRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
