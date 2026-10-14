@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardOverrideTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newBedBoardOverride("code-685", name: "name-319")
        #expect(item.status == BedManagement.BedBoardOverrideStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newBedBoardOverride("code-685", name: "name-319")
        try item.moveTo(BedManagement.BedBoardOverrideStatus.resolved)
        #expect(item.status == BedManagement.BedBoardOverrideStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newBedBoardOverride("code-685", name: "name-319")
        item.status = BedManagement.BedBoardOverrideStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardOverrideStatus.`open`) }
    }
}
