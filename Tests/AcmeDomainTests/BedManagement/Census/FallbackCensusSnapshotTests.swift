@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusSnapshotTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newFallbackCensusSnapshot("code-65", name: "name-907")
        #expect(item.status == BedManagement.FallbackCensusSnapshotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newFallbackCensusSnapshot("code-65", name: "name-907")
        try item.moveTo(BedManagement.FallbackCensusSnapshotStatus.revoked)
        #expect(item.status == BedManagement.FallbackCensusSnapshotStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newFallbackCensusSnapshot("code-65", name: "name-907")
        item.status = BedManagement.FallbackCensusSnapshotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackCensusSnapshotStatus.requested) }
    }
}
