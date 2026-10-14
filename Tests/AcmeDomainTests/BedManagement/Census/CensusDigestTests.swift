@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusDigestTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCensusDigest("code-781", title: "title-982")
        #expect(item.status == BedManagement.CensusDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newCensusDigest("code-781", title: "title-982")
        try item.moveTo(BedManagement.CensusDigestStatus.ready)
        #expect(item.status == BedManagement.CensusDigestStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCensusDigest("code-781", title: "title-982")
        item.status = BedManagement.CensusDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusDigestStatus.idle) }
    }
}
