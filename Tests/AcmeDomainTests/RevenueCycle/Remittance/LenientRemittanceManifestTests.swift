@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientRemittanceManifestTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newLenientRemittanceManifest("code-266", name: "name-980")
        #expect(item.status == RevenueCycle.LenientRemittanceManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newLenientRemittanceManifest("code-266", name: "name-980")
        try item.moveTo(RevenueCycle.LenientRemittanceManifestStatus.active)
        #expect(item.status == RevenueCycle.LenientRemittanceManifestStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newLenientRemittanceManifest("code-266", name: "name-980")
        item.status = RevenueCycle.LenientRemittanceManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LenientRemittanceManifestStatus.draft) }
    }
}
