@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardEntryTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newBedBoardEntry("code-232", title: "title-615")
        #expect(item.status == BedManagement.BedBoardEntryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newBedBoardEntry("code-232", title: "title-615")
        try item.moveTo(BedManagement.BedBoardEntryStatus.published)
        #expect(item.status == BedManagement.BedBoardEntryStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newBedBoardEntry("code-232", title: "title-615")
        item.status = BedManagement.BedBoardEntryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardEntryStatus.created) }
    }
}
