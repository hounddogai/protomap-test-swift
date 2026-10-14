@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusAssignmentTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newCensusAssignment("code-511", title: "title-422")
        #expect(item.status == BedManagement.CensusAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newCensusAssignment("code-511", title: "title-422")
        try item.moveTo(BedManagement.CensusAssignmentStatus.active)
        #expect(item.status == BedManagement.CensusAssignmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newCensusAssignment("code-511", title: "title-422")
        item.status = BedManagement.CensusAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusAssignmentStatus.draft) }
    }
}
