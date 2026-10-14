@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationProfileTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newIsolationProfile("code-917", name: "name-73")
        #expect(item.status == BedManagement.IsolationProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newIsolationProfile("code-917", name: "name-73")
        try item.moveTo(BedManagement.IsolationProfileStatus.published)
        #expect(item.status == BedManagement.IsolationProfileStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newIsolationProfile("code-917", name: "name-73")
        item.status = BedManagement.IsolationProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationProfileStatus.created) }
    }
}
