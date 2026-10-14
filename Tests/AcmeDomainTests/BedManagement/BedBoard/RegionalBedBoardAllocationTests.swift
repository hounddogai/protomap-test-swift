@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalBedBoardAllocationTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newRegionalBedBoardAllocation("code-731", title: "title-508")
        #expect(item.status == BedManagement.RegionalBedBoardAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newRegionalBedBoardAllocation("code-731", title: "title-508")
        try item.moveTo(BedManagement.RegionalBedBoardAllocationStatus.queued)
        #expect(item.status == BedManagement.RegionalBedBoardAllocationStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newRegionalBedBoardAllocation("code-731", title: "title-508")
        item.status = BedManagement.RegionalBedBoardAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RegionalBedBoardAllocationStatus.new) }
    }
}
