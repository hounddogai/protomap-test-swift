@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusAllocationTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newLegacyCensusAllocation("code-513", title: "title-779")
        #expect(item.status == BedManagement.LegacyCensusAllocationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newLegacyCensusAllocation("code-513", title: "title-779")
        try item.moveTo(BedManagement.LegacyCensusAllocationStatus.published)
        #expect(item.status == BedManagement.LegacyCensusAllocationStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newLegacyCensusAllocation("code-513", title: "title-779")
        item.status = BedManagement.LegacyCensusAllocationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyCensusAllocationStatus.created) }
    }
}
