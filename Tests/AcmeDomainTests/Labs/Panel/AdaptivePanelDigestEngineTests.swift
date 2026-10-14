@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultAdaptivePanelDigestEngine()
        let item = Labs.newAdaptivePanelDigest("code-810", title: "title-357")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
