@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertReservationTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newAlertReservation("code-506", title: "title-679")
        #expect(item.status == ClinicalOps.AlertReservationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newAlertReservation("code-506", title: "title-679")
        try item.moveTo(ClinicalOps.AlertReservationStatus.pending)
        #expect(item.status == ClinicalOps.AlertReservationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newAlertReservation("code-506", title: "title-679")
        item.status = ClinicalOps.AlertReservationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertReservationStatus.draft) }
    }
}
