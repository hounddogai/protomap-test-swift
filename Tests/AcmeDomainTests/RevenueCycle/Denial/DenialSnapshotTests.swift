@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialSnapshotTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newDenialSnapshot("code-593", name: "name-395")
        #expect(item.status == RevenueCycle.DenialSnapshotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newDenialSnapshot("code-593", name: "name-395")
        try item.moveTo(RevenueCycle.DenialSnapshotStatus.approved)
        #expect(item.status == RevenueCycle.DenialSnapshotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newDenialSnapshot("code-593", name: "name-395")
        item.status = RevenueCycle.DenialSnapshotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialSnapshotStatus.proposed) }
    }
}
