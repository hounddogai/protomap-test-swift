@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelClaimTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newPanelClaim("code-154", label: "label-218")
        #expect(item.status == Labs.PanelClaimStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Labs.newPanelClaim("code-154", label: "label-218")
        try item.moveTo(Labs.PanelClaimStatus.cancelled)
        #expect(item.status == Labs.PanelClaimStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newPanelClaim("code-154", label: "label-218")
        item.status = Labs.PanelClaimStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelClaimStatus.planned) }
    }
}
