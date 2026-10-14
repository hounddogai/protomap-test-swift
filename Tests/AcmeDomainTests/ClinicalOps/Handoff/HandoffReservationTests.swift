@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffReservationTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newHandoffReservation("code-473", title: "title-614")
        #expect(item.status == ClinicalOps.HandoffReservationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newHandoffReservation("code-473", title: "title-614")
        try item.moveTo(ClinicalOps.HandoffReservationStatus.approved)
        #expect(item.status == ClinicalOps.HandoffReservationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newHandoffReservation("code-473", title: "title-614")
        item.status = ClinicalOps.HandoffReservationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffReservationStatus.proposed) }
    }
}
