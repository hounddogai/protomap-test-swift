@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusAllocationTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newPendingCensusAllocation("code-575", title: "title-421")
        #expect(item.status == BedManagement.PendingCensusAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = BedManagement.newPendingCensusAllocation("code-575", title: "title-421")
        try item.moveTo(BedManagement.PendingCensusAllocationStatus.suspended)
        #expect(item.status == BedManagement.PendingCensusAllocationStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newPendingCensusAllocation("code-575", title: "title-421")
        item.status = BedManagement.PendingCensusAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PendingCensusAllocationStatus.draft) }
    }
}
