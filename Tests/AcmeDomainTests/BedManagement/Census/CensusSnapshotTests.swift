@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusSnapshotTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCensusSnapshot("code-671", label: "label-643")
        #expect(item.status == BedManagement.CensusSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newCensusSnapshot("code-671", label: "label-643")
        try item.moveTo(BedManagement.CensusSnapshotStatus.running)
        #expect(item.status == BedManagement.CensusSnapshotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCensusSnapshot("code-671", label: "label-643")
        item.status = BedManagement.CensusSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusSnapshotStatus.new) }
    }
}
