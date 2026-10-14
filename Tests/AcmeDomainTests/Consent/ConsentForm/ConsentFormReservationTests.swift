@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormReservationTests {
    @Test func startsInProposed() throws {
        let item = Consent.newConsentFormReservation("code-997", name: "name-817")
        #expect(item.status == Consent.ConsentFormReservationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newConsentFormReservation("code-997", name: "name-817")
        try item.moveTo(Consent.ConsentFormReservationStatus.rejected)
        #expect(item.status == Consent.ConsentFormReservationStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newConsentFormReservation("code-997", name: "name-817")
        item.status = Consent.ConsentFormReservationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormReservationStatus.proposed) }
    }
}
