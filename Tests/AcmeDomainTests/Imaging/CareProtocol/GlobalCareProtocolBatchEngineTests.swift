@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalCareProtocolBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultGlobalCareProtocolBatchEngine()
        let item = Imaging.newGlobalCareProtocolBatch("code-81", label: "label-503")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
