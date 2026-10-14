@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityReservationTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newPriorityReservation("code-789", name: "name-608")
        #expect(item.status == Imaging.PriorityReservationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newPriorityReservation("code-789", name: "name-608")
        try item.moveTo(Imaging.PriorityReservationStatus.rejected)
        #expect(item.status == Imaging.PriorityReservationStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newPriorityReservation("code-789", name: "name-608")
        item.status = Imaging.PriorityReservationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityReservationStatus.proposed) }
    }
}
