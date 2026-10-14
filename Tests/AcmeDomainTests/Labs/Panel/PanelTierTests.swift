@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelTierTests {
    @Test func startsInRequested() throws {
        let item = Labs.newPanelTier("code-653", label: "label-302")
        #expect(item.status == Labs.PanelTierStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newPanelTier("code-653", label: "label-302")
        try item.moveTo(Labs.PanelTierStatus.revoked)
        #expect(item.status == Labs.PanelTierStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newPanelTier("code-653", label: "label-302")
        item.status = Labs.PanelTierStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelTierStatus.requested) }
    }
}
