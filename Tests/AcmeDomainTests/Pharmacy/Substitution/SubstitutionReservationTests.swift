@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionReservationTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newSubstitutionReservation("code-882", title: "title-271")
        #expect(item.status == Pharmacy.SubstitutionReservationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newSubstitutionReservation("code-882", title: "title-271")
        try item.moveTo(Pharmacy.SubstitutionReservationStatus.pending)
        #expect(item.status == Pharmacy.SubstitutionReservationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newSubstitutionReservation("code-882", title: "title-271")
        item.status = Pharmacy.SubstitutionReservationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionReservationStatus.draft) }
    }
}
