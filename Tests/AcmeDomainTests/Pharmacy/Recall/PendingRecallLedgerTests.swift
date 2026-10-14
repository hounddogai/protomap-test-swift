@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallLedgerTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newPendingRecallLedger("code-610", label: "label-562")
        #expect(item.status == Pharmacy.PendingRecallLedgerStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newPendingRecallLedger("code-610", label: "label-562")
        try item.moveTo(Pharmacy.PendingRecallLedgerStatus.ready)
        #expect(item.status == Pharmacy.PendingRecallLedgerStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newPendingRecallLedger("code-610", label: "label-562")
        item.status = Pharmacy.PendingRecallLedgerStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingRecallLedgerStatus.idle) }
    }
}
