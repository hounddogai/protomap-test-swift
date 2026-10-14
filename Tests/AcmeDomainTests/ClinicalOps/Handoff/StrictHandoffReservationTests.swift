@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictHandoffReservationTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newStrictHandoffReservation("code-647", label: "label-646")
        #expect(item.status == ClinicalOps.StrictHandoffReservationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newStrictHandoffReservation("code-647", label: "label-646")
        try item.moveTo(ClinicalOps.StrictHandoffReservationStatus.resolved)
        #expect(item.status == ClinicalOps.StrictHandoffReservationStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newStrictHandoffReservation("code-647", label: "label-646")
        item.status = ClinicalOps.StrictHandoffReservationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictHandoffReservationStatus.`open`) }
    }
}
