@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictCareProtocolMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultStrictCareProtocolMappingEngine(Kit.Flags.newRegistry())
        let item = Imaging.newStrictCareProtocolMapping("code-564", title: "title-739")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
