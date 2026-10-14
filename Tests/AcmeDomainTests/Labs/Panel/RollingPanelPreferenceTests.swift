@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelPreferenceTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newRollingPanelPreference("code-842", label: "label-603")
        #expect(item.status == Labs.RollingPanelPreferenceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newRollingPanelPreference("code-842", label: "label-603")
        try item.moveTo(Labs.RollingPanelPreferenceStatus.completed)
        #expect(item.status == Labs.RollingPanelPreferenceStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newRollingPanelPreference("code-842", label: "label-603")
        item.status = Labs.RollingPanelPreferenceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingPanelPreferenceStatus.planned) }
    }
}
