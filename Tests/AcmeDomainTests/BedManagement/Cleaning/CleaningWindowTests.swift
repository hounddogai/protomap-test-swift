@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningWindowTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newCleaningWindow("code-888", title: "title-635")
        #expect(item.status == BedManagement.CleaningWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newCleaningWindow("code-888", title: "title-635")
        try item.moveTo(BedManagement.CleaningWindowStatus.resolved)
        #expect(item.status == BedManagement.CleaningWindowStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newCleaningWindow("code-888", title: "title-635")
        item.status = BedManagement.CleaningWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningWindowStatus.`open`) }
    }
}
