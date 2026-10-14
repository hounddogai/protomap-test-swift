@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyRoundingReservationTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newLegacyRoundingReservation("code-139", title: "title-353")
        #expect(item.status == ClinicalOps.LegacyRoundingReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newLegacyRoundingReservation("code-139", title: "title-353")
        try item.moveTo(ClinicalOps.LegacyRoundingReservationStatus.granted)
        #expect(item.status == ClinicalOps.LegacyRoundingReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newLegacyRoundingReservation("code-139", title: "title-353")
        item.status = ClinicalOps.LegacyRoundingReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyRoundingReservationStatus.requested) }
    }
}
