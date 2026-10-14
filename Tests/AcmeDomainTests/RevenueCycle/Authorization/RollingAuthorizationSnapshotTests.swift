@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingAuthorizationSnapshotTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newRollingAuthorizationSnapshot("code-181", name: "name-877")
        #expect(item.status == RevenueCycle.RollingAuthorizationSnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newRollingAuthorizationSnapshot("code-181", name: "name-877")
        try item.moveTo(RevenueCycle.RollingAuthorizationSnapshotStatus.resolved)
        #expect(item.status == RevenueCycle.RollingAuthorizationSnapshotStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newRollingAuthorizationSnapshot("code-181", name: "name-877")
        item.status = RevenueCycle.RollingAuthorizationSnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingAuthorizationSnapshotStatus.`open`) }
    }
}
