@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalPanelPolicyTests {
    @Test func startsInProposed() throws {
        let item = Labs.newSeasonalPanelPolicy("code-601", name: "name-582")
        #expect(item.status == Labs.SeasonalPanelPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newSeasonalPanelPolicy("code-601", name: "name-582")
        try item.moveTo(Labs.SeasonalPanelPolicyStatus.rejected)
        #expect(item.status == Labs.SeasonalPanelPolicyStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newSeasonalPanelPolicy("code-601", name: "name-582")
        item.status = Labs.SeasonalPanelPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalPanelPolicyStatus.proposed) }
    }
}
