@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRollingPanelPreferenceEngine()
        let item = Labs.newRollingPanelPreference("code-842", label: "label-603")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
