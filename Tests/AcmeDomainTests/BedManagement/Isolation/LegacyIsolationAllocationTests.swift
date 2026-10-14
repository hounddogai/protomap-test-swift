@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyIsolationAllocationTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newLegacyIsolationAllocation("code-402", title: "title-501")
        #expect(item.status == BedManagement.LegacyIsolationAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newLegacyIsolationAllocation("code-402", title: "title-501")
        try item.moveTo(BedManagement.LegacyIsolationAllocationStatus.inProgress)
        #expect(item.status == BedManagement.LegacyIsolationAllocationStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newLegacyIsolationAllocation("code-402", title: "title-501")
        item.status = BedManagement.LegacyIsolationAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyIsolationAllocationStatus.planned) }
    }
}
