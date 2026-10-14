@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedIsolationSegmentTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newWeightedIsolationSegment("code-323", name: "name-364")
        #expect(item.status == BedManagement.WeightedIsolationSegmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newWeightedIsolationSegment("code-323", name: "name-364")
        try item.moveTo(BedManagement.WeightedIsolationSegmentStatus.published)
        #expect(item.status == BedManagement.WeightedIsolationSegmentStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newWeightedIsolationSegment("code-323", name: "name-364")
        item.status = BedManagement.WeightedIsolationSegmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.WeightedIsolationSegmentStatus.created) }
    }
}
