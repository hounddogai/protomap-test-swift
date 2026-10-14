@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusAdjustmentTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCensusAdjustment("code-157", title: "title-118")
        #expect(item.status == BedManagement.CensusAdjustmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newCensusAdjustment("code-157", title: "title-118")
        try item.moveTo(BedManagement.CensusAdjustmentStatus.warming)
        #expect(item.status == BedManagement.CensusAdjustmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCensusAdjustment("code-157", title: "title-118")
        item.status = BedManagement.CensusAdjustmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusAdjustmentStatus.idle) }
    }
}
