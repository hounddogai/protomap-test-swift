@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCensusSegmentTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newCappedCensusSegment("code-991", name: "name-570")
        #expect(item.status == BedManagement.CappedCensusSegmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = BedManagement.newCappedCensusSegment("code-991", name: "name-570")
        try item.moveTo(BedManagement.CappedCensusSegmentStatus.archived)
        #expect(item.status == BedManagement.CappedCensusSegmentStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newCappedCensusSegment("code-991", name: "name-570")
        item.status = BedManagement.CappedCensusSegmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedCensusSegmentStatus.`open`) }
    }
}
