@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualAuthorizationSnapshotTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newManualAuthorizationSnapshot("code-152", title: "title-308")
        #expect(item.status == RevenueCycle.ManualAuthorizationSnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newManualAuthorizationSnapshot("code-152", title: "title-308")
        try item.moveTo(RevenueCycle.ManualAuthorizationSnapshotStatus.reopened)
        #expect(item.status == RevenueCycle.ManualAuthorizationSnapshotStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newManualAuthorizationSnapshot("code-152", title: "title-308")
        item.status = RevenueCycle.ManualAuthorizationSnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualAuthorizationSnapshotStatus.`open`) }
    }
}
