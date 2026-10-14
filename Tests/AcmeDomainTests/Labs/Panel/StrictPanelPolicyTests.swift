@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictPanelPolicyTests {
    @Test func startsInRequested() throws {
        let item = Labs.newStrictPanelPolicy("code-496", title: "title-719")
        #expect(item.status == Labs.StrictPanelPolicyStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newStrictPanelPolicy("code-496", title: "title-719")
        try item.moveTo(Labs.StrictPanelPolicyStatus.granted)
        #expect(item.status == Labs.StrictPanelPolicyStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newStrictPanelPolicy("code-496", title: "title-719")
        item.status = Labs.StrictPanelPolicyStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.StrictPanelPolicyStatus.requested) }
    }
}
