@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingClaimRecordTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newRollingClaimRecord("code-67", name: "name-97")
        #expect(item.status == RevenueCycle.RollingClaimRecordStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newRollingClaimRecord("code-67", name: "name-97")
        try item.moveTo(RevenueCycle.RollingClaimRecordStatus.queued)
        #expect(item.status == RevenueCycle.RollingClaimRecordStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newRollingClaimRecord("code-67", name: "name-97")
        item.status = RevenueCycle.RollingClaimRecordStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingClaimRecordStatus.new) }
    }
}
