@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultHandoffReservationTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newDefaultHandoffReservation("code-104", title: "title-635")
        #expect(item.status == ClinicalOps.DefaultHandoffReservationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newDefaultHandoffReservation("code-104", title: "title-635")
        try item.moveTo(ClinicalOps.DefaultHandoffReservationStatus.pending)
        #expect(item.status == ClinicalOps.DefaultHandoffReservationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newDefaultHandoffReservation("code-104", title: "title-635")
        item.status = ClinicalOps.DefaultHandoffReservationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultHandoffReservationStatus.draft) }
    }
}
