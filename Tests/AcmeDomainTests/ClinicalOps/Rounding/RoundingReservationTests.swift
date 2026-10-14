@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingReservationTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newRoundingReservation("code-675", name: "name-399")
        #expect(item.status == ClinicalOps.RoundingReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newRoundingReservation("code-675", name: "name-399")
        try item.moveTo(ClinicalOps.RoundingReservationStatus.revoked)
        #expect(item.status == ClinicalOps.RoundingReservationStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newRoundingReservation("code-675", name: "name-399")
        item.status = ClinicalOps.RoundingReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingReservationStatus.requested) }
    }
}
