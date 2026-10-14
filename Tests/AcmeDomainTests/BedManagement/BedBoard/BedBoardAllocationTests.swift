@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardAllocationTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newBedBoardAllocation("code-645", label: "label-526")
        #expect(item.status == BedManagement.BedBoardAllocationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newBedBoardAllocation("code-645", label: "label-526")
        try item.moveTo(BedManagement.BedBoardAllocationStatus.warming)
        #expect(item.status == BedManagement.BedBoardAllocationStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newBedBoardAllocation("code-645", label: "label-526")
        item.status = BedManagement.BedBoardAllocationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardAllocationStatus.idle) }
    }
}
