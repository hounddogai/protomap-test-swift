@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelQuotaTests {
    @Test func startsInRequested() throws {
        let item = Labs.newPanelQuota("code-896", title: "title-768")
        #expect(item.status == Labs.PanelQuotaStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newPanelQuota("code-896", title: "title-768")
        try item.moveTo(Labs.PanelQuotaStatus.granted)
        #expect(item.status == Labs.PanelQuotaStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newPanelQuota("code-896", title: "title-768")
        item.status = Labs.PanelQuotaStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelQuotaStatus.requested) }
    }
}
