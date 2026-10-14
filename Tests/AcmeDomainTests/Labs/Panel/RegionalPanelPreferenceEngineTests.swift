@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalPanelPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRegionalPanelPreferenceEngine(Kit.Flags.newRegistry())
        let item = Labs.newRegionalPanelPreference("code-963", label: "label-386")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
