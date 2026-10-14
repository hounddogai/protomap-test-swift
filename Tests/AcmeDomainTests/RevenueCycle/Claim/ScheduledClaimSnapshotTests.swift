@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledClaimSnapshotTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newScheduledClaimSnapshot("code-278", name: "name-28")
        #expect(item.status == RevenueCycle.ScheduledClaimSnapshotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newScheduledClaimSnapshot("code-278", name: "name-28")
        try item.moveTo(RevenueCycle.ScheduledClaimSnapshotStatus.approved)
        #expect(item.status == RevenueCycle.ScheduledClaimSnapshotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newScheduledClaimSnapshot("code-278", name: "name-28")
        item.status = RevenueCycle.ScheduledClaimSnapshotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ScheduledClaimSnapshotStatus.proposed) }
    }
}
