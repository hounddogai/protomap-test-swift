@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelPreferenceEngine()
        let item = Labs.newPanelPreference("code-189", title: "title-112")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
