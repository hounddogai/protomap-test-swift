@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelVarianceTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newPanelVariance("code-997", label: "label-44")
        #expect(item.status == Labs.PanelVarianceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newPanelVariance("code-997", label: "label-44")
        try item.moveTo(Labs.PanelVarianceStatus.scheduled)
        #expect(item.status == Labs.PanelVarianceStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newPanelVariance("code-997", label: "label-44")
        item.status = Labs.PanelVarianceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelVarianceStatus.planned) }
    }
}
