@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingProxyWindowTests {
    @Test func startsInIdle() throws {
        let item = Consent.newRollingProxyWindow("code-781", name: "name-112")
        #expect(item.status == Consent.RollingProxyWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newRollingProxyWindow("code-781", name: "name-112")
        try item.moveTo(Consent.RollingProxyWindowStatus.warming)
        #expect(item.status == Consent.RollingProxyWindowStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newRollingProxyWindow("code-781", name: "name-112")
        item.status = Consent.RollingProxyWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingProxyWindowStatus.idle) }
    }
}
