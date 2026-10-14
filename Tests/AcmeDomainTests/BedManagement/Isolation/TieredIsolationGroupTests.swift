@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredIsolationGroupTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newTieredIsolationGroup("code-315", name: "name-804")
        #expect(item.status == BedManagement.TieredIsolationGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newTieredIsolationGroup("code-315", name: "name-804")
        try item.moveTo(BedManagement.TieredIsolationGroupStatus.revoked)
        #expect(item.status == BedManagement.TieredIsolationGroupStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newTieredIsolationGroup("code-315", name: "name-804")
        item.status = BedManagement.TieredIsolationGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TieredIsolationGroupStatus.requested) }
    }
}
