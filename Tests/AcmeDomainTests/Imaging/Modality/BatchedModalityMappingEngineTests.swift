@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedModalityMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultBatchedModalityMappingEngine()
        let item = Imaging.newBatchedModalityMapping("code-226", name: "name-48")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
