@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictDenialManifestTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newStrictDenialManifest("code-97", title: "title-173")
        #expect(item.status == RevenueCycle.StrictDenialManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newStrictDenialManifest("code-97", title: "title-173")
        try item.moveTo(RevenueCycle.StrictDenialManifestStatus.pending)
        #expect(item.status == RevenueCycle.StrictDenialManifestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newStrictDenialManifest("code-97", title: "title-173")
        item.status = RevenueCycle.StrictDenialManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictDenialManifestStatus.draft) }
    }
}
