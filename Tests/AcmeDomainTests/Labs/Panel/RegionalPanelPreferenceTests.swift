@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalPanelPreferenceTests {
    @Test func startsInIdle() throws {
        let item = Labs.newRegionalPanelPreference("code-963", label: "label-386")
        #expect(item.status == Labs.RegionalPanelPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newRegionalPanelPreference("code-963", label: "label-386")
        try item.moveTo(Labs.RegionalPanelPreferenceStatus.ready)
        #expect(item.status == Labs.RegionalPanelPreferenceStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newRegionalPanelPreference("code-963", label: "label-386")
        item.status = Labs.RegionalPanelPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalPanelPreferenceStatus.idle) }
    }
}
