@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationSnapshotTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newLegacyAuthorizationSnapshot("code-640", label: "label-117")
        #expect(item.status == RevenueCycle.LegacyAuthorizationSnapshotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newLegacyAuthorizationSnapshot("code-640", label: "label-117")
        try item.moveTo(RevenueCycle.LegacyAuthorizationSnapshotStatus.completed)
        #expect(item.status == RevenueCycle.LegacyAuthorizationSnapshotStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newLegacyAuthorizationSnapshot("code-640", label: "label-117")
        item.status = RevenueCycle.LegacyAuthorizationSnapshotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyAuthorizationSnapshotStatus.planned) }
    }
}
