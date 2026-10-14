@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimManifestTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newClaimManifest("code-509", name: "name-571")
        #expect(item.status == RevenueCycle.ClaimManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newClaimManifest("code-509", name: "name-571")
        try item.moveTo(RevenueCycle.ClaimManifestStatus.suspended)
        #expect(item.status == RevenueCycle.ClaimManifestStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newClaimManifest("code-509", name: "name-571")
        item.status = RevenueCycle.ClaimManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimManifestStatus.draft) }
    }
}
