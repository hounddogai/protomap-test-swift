@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelAgreementTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPanelAgreement("code-446", title: "title-279")
        #expect(item.status == Labs.PanelAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newPanelAgreement("code-446", title: "title-279")
        try item.moveTo(Labs.PanelAgreementStatus.pending)
        #expect(item.status == Labs.PanelAgreementStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPanelAgreement("code-446", title: "title-279")
        item.status = Labs.PanelAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelAgreementStatus.draft) }
    }
}
