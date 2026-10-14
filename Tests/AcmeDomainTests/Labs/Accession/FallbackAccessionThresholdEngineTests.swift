@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultFallbackAccessionThresholdEngine()
        let item = Labs.newFallbackAccessionThreshold("code-632", name: "name-839")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
