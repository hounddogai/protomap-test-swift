@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultCareProtocolMappingEngine(Kit.Flags.newRegistry())
        let item = Imaging.newCareProtocolMapping("code-346", label: "label-166")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
