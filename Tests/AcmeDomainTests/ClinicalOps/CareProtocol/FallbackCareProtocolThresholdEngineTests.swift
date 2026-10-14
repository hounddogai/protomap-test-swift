@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackCareProtocolThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultFallbackCareProtocolThresholdEngine()
        let item = ClinicalOps.newFallbackCareProtocolThreshold("code-317", title: "title-358")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
