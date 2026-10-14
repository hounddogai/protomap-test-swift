@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingDisclosureWindowTests {
    @Test func startsInIdle() throws {
        let item = Consent.newPendingDisclosureWindow("code-578", name: "name-613")
        #expect(item.status == Consent.PendingDisclosureWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newPendingDisclosureWindow("code-578", name: "name-613")
        try item.moveTo(Consent.PendingDisclosureWindowStatus.warming)
        #expect(item.status == Consent.PendingDisclosureWindowStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newPendingDisclosureWindow("code-578", name: "name-613")
        item.status = Consent.PendingDisclosureWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PendingDisclosureWindowStatus.idle) }
    }
}
