@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalOutreachEntryTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newRegionalOutreachEntry("code-745", label: "label-802")
        #expect(item.status == CareManagement.RegionalOutreachEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newRegionalOutreachEntry("code-745", label: "label-802")
        try item.moveTo(CareManagement.RegionalOutreachEntryStatus.active)
        #expect(item.status == CareManagement.RegionalOutreachEntryStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newRegionalOutreachEntry("code-745", label: "label-802")
        item.status = CareManagement.RegionalOutreachEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalOutreachEntryStatus.draft) }
    }
}
