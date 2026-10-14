@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelVarianceEngine()
        let item = Labs.newPanelVariance("code-997", label: "label-44")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
