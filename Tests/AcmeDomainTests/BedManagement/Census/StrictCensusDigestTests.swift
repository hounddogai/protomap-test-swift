@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictCensusDigestTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newStrictCensusDigest("code-460", title: "title-586")
        #expect(item.status == BedManagement.StrictCensusDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = BedManagement.newStrictCensusDigest("code-460", title: "title-586")
        try item.moveTo(BedManagement.StrictCensusDigestStatus.expired)
        #expect(item.status == BedManagement.StrictCensusDigestStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newStrictCensusDigest("code-460", title: "title-586")
        item.status = BedManagement.StrictCensusDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.StrictCensusDigestStatus.requested) }
    }
}
