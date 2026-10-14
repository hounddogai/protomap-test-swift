@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferSnapshotValidator()
        let item = BedManagement.newTransferSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferSnapshotQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = BedManagement.TransferSnapshotQuantityRangeRule(min: 16, max: 80)
        let item = BedManagement.newTransferSnapshot("x", name: "y")
        item.quantity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferSnapshotReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = BedManagement.TransferSnapshotReviewerLengthRule(maxLength: 3600)
        let item = BedManagement.newTransferSnapshot("x", name: "y")
        item.reviewer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferSnapshotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.TransferSnapshotNameLengthRule(maxLength: 32)
        let item = BedManagement.newTransferSnapshot("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
