@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledAuthorizationSnapshotTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newScheduledAuthorizationSnapshot("code-854", title: "title-337")
        #expect(item.status == RevenueCycle.ScheduledAuthorizationSnapshotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newScheduledAuthorizationSnapshot("code-854", title: "title-337")
        try item.moveTo(RevenueCycle.ScheduledAuthorizationSnapshotStatus.approved)
        #expect(item.status == RevenueCycle.ScheduledAuthorizationSnapshotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newScheduledAuthorizationSnapshot("code-854", title: "title-337")
        item.status = RevenueCycle.ScheduledAuthorizationSnapshotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ScheduledAuthorizationSnapshotStatus.proposed) }
    }
}
