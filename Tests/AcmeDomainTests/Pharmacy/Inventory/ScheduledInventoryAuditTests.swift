@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryAuditTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newScheduledInventoryAudit("code-288", title: "title-332")
        #expect(item.status == Pharmacy.ScheduledInventoryAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newScheduledInventoryAudit("code-288", title: "title-332")
        try item.moveTo(Pharmacy.ScheduledInventoryAuditStatus.validated)
        #expect(item.status == Pharmacy.ScheduledInventoryAuditStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newScheduledInventoryAudit("code-288", title: "title-332")
        item.status = Pharmacy.ScheduledInventoryAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ScheduledInventoryAuditStatus.created) }
    }
}
