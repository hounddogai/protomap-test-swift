@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingLanguageDigestTests {
    @Test func startsInIdle() throws {
        let item = Consent.newPendingLanguageDigest("code-383", name: "name-28")
        #expect(item.status == Consent.PendingLanguageDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newPendingLanguageDigest("code-383", name: "name-28")
        try item.moveTo(Consent.PendingLanguageDigestStatus.ready)
        #expect(item.status == Consent.PendingLanguageDigestStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newPendingLanguageDigest("code-383", name: "name-28")
        item.status = Consent.PendingLanguageDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PendingLanguageDigestStatus.idle) }
    }
}
