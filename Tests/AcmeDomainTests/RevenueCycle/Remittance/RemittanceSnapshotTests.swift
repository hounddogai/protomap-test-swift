@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceSnapshotTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRemittanceSnapshot("code-65", name: "name-106")
        #expect(item.status == RevenueCycle.RemittanceSnapshotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newRemittanceSnapshot("code-65", name: "name-106")
        try item.moveTo(RevenueCycle.RemittanceSnapshotStatus.warming)
        #expect(item.status == RevenueCycle.RemittanceSnapshotStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRemittanceSnapshot("code-65", name: "name-106")
        item.status = RevenueCycle.RemittanceSnapshotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceSnapshotStatus.idle) }
    }
}
