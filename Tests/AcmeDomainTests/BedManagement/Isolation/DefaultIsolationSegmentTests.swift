@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultIsolationSegmentTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newDefaultIsolationSegment("code-501", name: "name-65")
        #expect(item.status == BedManagement.DefaultIsolationSegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newDefaultIsolationSegment("code-501", name: "name-65")
        try item.moveTo(BedManagement.DefaultIsolationSegmentStatus.ready)
        #expect(item.status == BedManagement.DefaultIsolationSegmentStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newDefaultIsolationSegment("code-501", name: "name-65")
        item.status = BedManagement.DefaultIsolationSegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultIsolationSegmentStatus.idle) }
    }
}
