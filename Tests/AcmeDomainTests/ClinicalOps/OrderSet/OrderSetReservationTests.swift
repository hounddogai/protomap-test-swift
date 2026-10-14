@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetReservationTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newOrderSetReservation("code-624", label: "label-564")
        #expect(item.status == ClinicalOps.OrderSetReservationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newOrderSetReservation("code-624", label: "label-564")
        try item.moveTo(ClinicalOps.OrderSetReservationStatus.scheduled)
        #expect(item.status == ClinicalOps.OrderSetReservationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newOrderSetReservation("code-624", label: "label-564")
        item.status = ClinicalOps.OrderSetReservationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetReservationStatus.planned) }
    }
}
