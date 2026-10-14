@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusBundleTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newFallbackCensusBundle("code-209", name: "name-718")
        #expect(item.status == BedManagement.FallbackCensusBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newFallbackCensusBundle("code-209", name: "name-718")
        try item.moveTo(BedManagement.FallbackCensusBundleStatus.ready)
        #expect(item.status == BedManagement.FallbackCensusBundleStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newFallbackCensusBundle("code-209", name: "name-718")
        item.status = BedManagement.FallbackCensusBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackCensusBundleStatus.idle) }
    }
}
