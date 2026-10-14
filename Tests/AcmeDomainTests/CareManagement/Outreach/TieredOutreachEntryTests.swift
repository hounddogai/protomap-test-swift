@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachEntryTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newTieredOutreachEntry("code-989", name: "name-431")
        #expect(item.status == CareManagement.TieredOutreachEntryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newTieredOutreachEntry("code-989", name: "name-431")
        try item.moveTo(CareManagement.TieredOutreachEntryStatus.published)
        #expect(item.status == CareManagement.TieredOutreachEntryStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newTieredOutreachEntry("code-989", name: "name-431")
        item.status = CareManagement.TieredOutreachEntryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredOutreachEntryStatus.created) }
    }
}
