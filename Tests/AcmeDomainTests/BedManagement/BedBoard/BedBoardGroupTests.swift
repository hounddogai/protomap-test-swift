@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardGroupTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newBedBoardGroup("code-12", name: "name-372")
        #expect(item.status == BedManagement.BedBoardGroupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newBedBoardGroup("code-12", name: "name-372")
        try item.moveTo(BedManagement.BedBoardGroupStatus.published)
        #expect(item.status == BedManagement.BedBoardGroupStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newBedBoardGroup("code-12", name: "name-372")
        item.status = BedManagement.BedBoardGroupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardGroupStatus.created) }
    }
}
