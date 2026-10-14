@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferReservationTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newWeightedTransferReservation("code-936", title: "title-842")
        #expect(item.status == BedManagement.WeightedTransferReservationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newWeightedTransferReservation("code-936", title: "title-842")
        try item.moveTo(BedManagement.WeightedTransferReservationStatus.active)
        #expect(item.status == BedManagement.WeightedTransferReservationStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newWeightedTransferReservation("code-936", title: "title-842")
        item.status = BedManagement.WeightedTransferReservationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.WeightedTransferReservationStatus.draft) }
    }
}
