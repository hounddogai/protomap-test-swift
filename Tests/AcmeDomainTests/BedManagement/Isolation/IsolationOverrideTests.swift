@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationOverrideTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newIsolationOverride("code-545", title: "title-209")
        #expect(item.status == BedManagement.IsolationOverrideStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newIsolationOverride("code-545", title: "title-209")
        try item.moveTo(BedManagement.IsolationOverrideStatus.inReview)
        #expect(item.status == BedManagement.IsolationOverrideStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newIsolationOverride("code-545", title: "title-209")
        item.status = BedManagement.IsolationOverrideStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationOverrideStatus.`open`) }
    }
}
