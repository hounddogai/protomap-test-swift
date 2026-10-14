@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalProxyReservationTests {
    @Test func startsInRequested() throws {
        let item = Consent.newGlobalProxyReservation("code-843", label: "label-736")
        #expect(item.status == Consent.GlobalProxyReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newGlobalProxyReservation("code-843", label: "label-736")
        try item.moveTo(Consent.GlobalProxyReservationStatus.granted)
        #expect(item.status == Consent.GlobalProxyReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newGlobalProxyReservation("code-843", label: "label-736")
        item.status = Consent.GlobalProxyReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.GlobalProxyReservationStatus.requested) }
    }
}
