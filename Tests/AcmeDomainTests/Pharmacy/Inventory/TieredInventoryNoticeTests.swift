@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredInventoryNoticeTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newTieredInventoryNotice("code-552", name: "name-944")
        #expect(item.status == Pharmacy.TieredInventoryNoticeStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newTieredInventoryNotice("code-552", name: "name-944")
        try item.moveTo(Pharmacy.TieredInventoryNoticeStatus.rejected)
        #expect(item.status == Pharmacy.TieredInventoryNoticeStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newTieredInventoryNotice("code-552", name: "name-944")
        item.status = Pharmacy.TieredInventoryNoticeStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.TieredInventoryNoticeStatus.proposed) }
    }
}
