@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultFallbackCareProtocolWindowEngine(Kit.Flags.newRegistry())
        let item = Imaging.newFallbackCareProtocolWindow("code-739", title: "title-469")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
