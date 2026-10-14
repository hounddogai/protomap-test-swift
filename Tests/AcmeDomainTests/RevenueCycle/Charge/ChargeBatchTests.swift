@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeBatchTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newChargeBatch("code-432", name: "name-223")
        #expect(item.status == RevenueCycle.ChargeBatchStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newChargeBatch("code-432", name: "name-223")
        try item.moveTo(RevenueCycle.ChargeBatchStatus.revoked)
        #expect(item.status == RevenueCycle.ChargeBatchStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newChargeBatch("code-432", name: "name-223")
        item.status = RevenueCycle.ChargeBatchStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeBatchStatus.requested) }
    }
}
