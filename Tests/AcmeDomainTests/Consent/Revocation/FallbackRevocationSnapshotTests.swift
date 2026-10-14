@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackRevocationSnapshotTests {
    @Test func startsInIdle() throws {
        let item = Consent.newFallbackRevocationSnapshot("code-174", title: "title-379")
        #expect(item.status == Consent.FallbackRevocationSnapshotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newFallbackRevocationSnapshot("code-174", title: "title-379")
        try item.moveTo(Consent.FallbackRevocationSnapshotStatus.ready)
        #expect(item.status == Consent.FallbackRevocationSnapshotStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newFallbackRevocationSnapshot("code-174", title: "title-379")
        item.status = Consent.FallbackRevocationSnapshotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackRevocationSnapshotStatus.idle) }
    }
}
