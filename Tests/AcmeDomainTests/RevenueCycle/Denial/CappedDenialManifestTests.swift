@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedDenialManifestTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newCappedDenialManifest("code-750", label: "label-232")
        #expect(item.status == RevenueCycle.CappedDenialManifestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newCappedDenialManifest("code-750", label: "label-232")
        try item.moveTo(RevenueCycle.CappedDenialManifestStatus.queued)
        #expect(item.status == RevenueCycle.CappedDenialManifestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newCappedDenialManifest("code-750", label: "label-232")
        item.status = RevenueCycle.CappedDenialManifestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedDenialManifestStatus.new) }
    }
}
