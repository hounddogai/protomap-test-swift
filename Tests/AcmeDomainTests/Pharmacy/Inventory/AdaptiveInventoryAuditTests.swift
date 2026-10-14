@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInventoryAuditTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newAdaptiveInventoryAudit("code-346", name: "name-605")
        #expect(item.status == Pharmacy.AdaptiveInventoryAuditStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Pharmacy.newAdaptiveInventoryAudit("code-346", name: "name-605")
        try item.moveTo(Pharmacy.AdaptiveInventoryAuditStatus.done)
        #expect(item.status == Pharmacy.AdaptiveInventoryAuditStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newAdaptiveInventoryAudit("code-346", name: "name-605")
        item.status = Pharmacy.AdaptiveInventoryAuditStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveInventoryAuditStatus.new) }
    }
}
