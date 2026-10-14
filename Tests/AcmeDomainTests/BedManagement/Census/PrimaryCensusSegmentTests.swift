@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCensusSegmentTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newPrimaryCensusSegment("code-202", label: "label-511")
        #expect(item.status == BedManagement.PrimaryCensusSegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = BedManagement.newPrimaryCensusSegment("code-202", label: "label-511")
        try item.moveTo(BedManagement.PrimaryCensusSegmentStatus.draining)
        #expect(item.status == BedManagement.PrimaryCensusSegmentStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newPrimaryCensusSegment("code-202", label: "label-511")
        item.status = BedManagement.PrimaryCensusSegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryCensusSegmentStatus.idle) }
    }
}
