@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallRollupTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newPendingRecallRollup("code-812", title: "title-840")
        #expect(item.status == Pharmacy.PendingRecallRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newPendingRecallRollup("code-812", title: "title-840")
        try item.moveTo(Pharmacy.PendingRecallRollupStatus.active)
        #expect(item.status == Pharmacy.PendingRecallRollupStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newPendingRecallRollup("code-812", title: "title-840")
        item.status = Pharmacy.PendingRecallRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingRecallRollupStatus.draft) }
    }
}
