@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureCheckpointTests {
    @Test func startsInRequested() throws {
        let item = Consent.newDisclosureCheckpoint("code-799", title: "title-782")
        #expect(item.status == Consent.DisclosureCheckpointStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newDisclosureCheckpoint("code-799", title: "title-782")
        try item.moveTo(Consent.DisclosureCheckpointStatus.revoked)
        #expect(item.status == Consent.DisclosureCheckpointStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newDisclosureCheckpoint("code-799", title: "title-782")
        item.status = Consent.DisclosureCheckpointStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureCheckpointStatus.requested) }
    }
}
