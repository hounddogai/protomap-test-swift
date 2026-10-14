@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyReservationTests {
    @Test func startsInIdle() throws {
        let item = Consent.newProxyReservation("code-761", name: "name-273")
        #expect(item.status == Consent.ProxyReservationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Consent.newProxyReservation("code-761", name: "name-273")
        try item.moveTo(Consent.ProxyReservationStatus.draining)
        #expect(item.status == Consent.ProxyReservationStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newProxyReservation("code-761", name: "name-273")
        item.status = Consent.ProxyReservationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyReservationStatus.idle) }
    }
}
