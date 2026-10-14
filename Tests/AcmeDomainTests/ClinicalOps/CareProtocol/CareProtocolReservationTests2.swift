@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolReservationTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newCareProtocolReservation("code-390", name: "name-673")
        #expect(item.status == ClinicalOps.CareProtocolReservationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newCareProtocolReservation("code-390", name: "name-673")
        try item.moveTo(ClinicalOps.CareProtocolReservationStatus.pending)
        #expect(item.status == ClinicalOps.CareProtocolReservationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newCareProtocolReservation("code-390", name: "name-673")
        item.status = ClinicalOps.CareProtocolReservationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolReservationStatus.draft) }
    }
}
