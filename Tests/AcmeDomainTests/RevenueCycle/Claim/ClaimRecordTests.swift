@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimRecordTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newClaimRecord("code-593", name: "name-865")
        #expect(item.status == RevenueCycle.ClaimRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = RevenueCycle.newClaimRecord("code-593", name: "name-865")
        try item.moveTo(RevenueCycle.ClaimRecordStatus.stopped)
        #expect(item.status == RevenueCycle.ClaimRecordStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newClaimRecord("code-593", name: "name-865")
        item.status = RevenueCycle.ClaimRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimRecordStatus.idle) }
    }
}
