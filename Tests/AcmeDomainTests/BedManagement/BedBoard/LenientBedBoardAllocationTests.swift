@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientBedBoardAllocationTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newLenientBedBoardAllocation("code-47", label: "label-987")
        #expect(item.status == BedManagement.LenientBedBoardAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newLenientBedBoardAllocation("code-47", label: "label-987")
        try item.moveTo(BedManagement.LenientBedBoardAllocationStatus.queued)
        #expect(item.status == BedManagement.LenientBedBoardAllocationStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newLenientBedBoardAllocation("code-47", label: "label-987")
        item.status = BedManagement.LenientBedBoardAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientBedBoardAllocationStatus.new) }
    }
}
