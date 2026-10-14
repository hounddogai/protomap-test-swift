@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingBedBoardDraftTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newRollingBedBoardDraft("code-784", name: "name-398")
        #expect(item.status == BedManagement.RollingBedBoardDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = BedManagement.newRollingBedBoardDraft("code-784", name: "name-398")
        try item.moveTo(BedManagement.RollingBedBoardDraftStatus.retired)
        #expect(item.status == BedManagement.RollingBedBoardDraftStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newRollingBedBoardDraft("code-784", name: "name-398")
        item.status = BedManagement.RollingBedBoardDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingBedBoardDraftStatus.created) }
    }
}
