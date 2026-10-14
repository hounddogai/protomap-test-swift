@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelSummaryTests {
    @Test func startsInRequested() throws {
        let item = Labs.newPanelSummary("code-215", label: "label-40")
        #expect(item.status == Labs.PanelSummaryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newPanelSummary("code-215", label: "label-40")
        try item.moveTo(Labs.PanelSummaryStatus.expired)
        #expect(item.status == Labs.PanelSummaryStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newPanelSummary("code-215", label: "label-40")
        item.status = Labs.PanelSummaryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelSummaryStatus.requested) }
    }
}
