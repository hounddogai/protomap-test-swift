@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationReservationTests {
    @Test func startsInCreated() throws {
        let item = Consent.newRevocationReservation("code-221", label: "label-523")
        #expect(item.status == Consent.RevocationReservationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newRevocationReservation("code-221", label: "label-523")
        try item.moveTo(Consent.RevocationReservationStatus.validated)
        #expect(item.status == Consent.RevocationReservationStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newRevocationReservation("code-221", label: "label-523")
        item.status = Consent.RevocationReservationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationReservationStatus.created) }
    }
}
