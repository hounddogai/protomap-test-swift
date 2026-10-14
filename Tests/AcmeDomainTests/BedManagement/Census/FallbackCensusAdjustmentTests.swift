@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusAdjustmentTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newFallbackCensusAdjustment("code-999", name: "name-764")
        #expect(item.status == BedManagement.FallbackCensusAdjustmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newFallbackCensusAdjustment("code-999", name: "name-764")
        try item.moveTo(BedManagement.FallbackCensusAdjustmentStatus.warming)
        #expect(item.status == BedManagement.FallbackCensusAdjustmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newFallbackCensusAdjustment("code-999", name: "name-764")
        item.status = BedManagement.FallbackCensusAdjustmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackCensusAdjustmentStatus.idle) }
    }
}
