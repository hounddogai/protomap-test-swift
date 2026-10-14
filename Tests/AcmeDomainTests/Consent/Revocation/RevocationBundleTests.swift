@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationBundleTests {
    @Test func startsInNew() throws {
        let item = Consent.newRevocationBundle("code-562", title: "title-765")
        #expect(item.status == Consent.RevocationBundleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newRevocationBundle("code-562", title: "title-765")
        try item.moveTo(Consent.RevocationBundleStatus.queued)
        #expect(item.status == Consent.RevocationBundleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newRevocationBundle("code-562", title: "title-765")
        item.status = Consent.RevocationBundleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationBundleStatus.new) }
    }
}
