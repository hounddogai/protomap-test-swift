@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusAllocationTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newCensusAllocation("code-928", title: "title-173")
        #expect(item.status == BedManagement.CensusAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newCensusAllocation("code-928", title: "title-173")
        try item.moveTo(BedManagement.CensusAllocationStatus.scheduled)
        #expect(item.status == BedManagement.CensusAllocationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newCensusAllocation("code-928", title: "title-173")
        item.status = BedManagement.CensusAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusAllocationStatus.planned) }
    }
}
