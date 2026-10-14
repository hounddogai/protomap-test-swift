@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredShiftDigestTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newTieredShiftDigest("code-485", title: "title-349")
        #expect(item.status == Staffing.TieredShiftDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Staffing.newTieredShiftDigest("code-485", title: "title-349")
        try item.moveTo(Staffing.TieredShiftDigestStatus.draining)
        #expect(item.status == Staffing.TieredShiftDigestStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newTieredShiftDigest("code-485", title: "title-349")
        item.status = Staffing.TieredShiftDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredShiftDigestStatus.idle) }
    }
}
