@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingChargeBatchTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newPendingChargeBatch("code-864", title: "title-214")
        #expect(item.status == RevenueCycle.PendingChargeBatchStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newPendingChargeBatch("code-864", title: "title-214")
        try item.moveTo(RevenueCycle.PendingChargeBatchStatus.granted)
        #expect(item.status == RevenueCycle.PendingChargeBatchStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newPendingChargeBatch("code-864", title: "title-214")
        item.status = RevenueCycle.PendingChargeBatchStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingChargeBatchStatus.requested) }
    }
}
