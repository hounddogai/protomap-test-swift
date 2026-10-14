@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryIsolationTargetTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newPrimaryIsolationTarget("code-202", name: "name-332")
        #expect(item.status == BedManagement.PrimaryIsolationTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newPrimaryIsolationTarget("code-202", name: "name-332")
        try item.moveTo(BedManagement.PrimaryIsolationTargetStatus.ready)
        #expect(item.status == BedManagement.PrimaryIsolationTargetStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newPrimaryIsolationTarget("code-202", name: "name-332")
        item.status = BedManagement.PrimaryIsolationTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryIsolationTargetStatus.idle) }
    }
}
