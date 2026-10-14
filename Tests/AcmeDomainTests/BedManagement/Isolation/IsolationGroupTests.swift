@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationGroupTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newIsolationGroup("code-842", title: "title-79")
        #expect(item.status == BedManagement.IsolationGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newIsolationGroup("code-842", title: "title-79")
        try item.moveTo(BedManagement.IsolationGroupStatus.inReview)
        #expect(item.status == BedManagement.IsolationGroupStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newIsolationGroup("code-842", title: "title-79")
        item.status = BedManagement.IsolationGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationGroupStatus.`open`) }
    }
}
