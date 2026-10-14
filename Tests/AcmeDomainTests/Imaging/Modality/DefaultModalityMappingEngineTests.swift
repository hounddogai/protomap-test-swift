@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultModalityMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultDefaultModalityMappingEngine(Kit.Flags.newRegistry())
        let item = Imaging.newDefaultModalityMapping("code-10", title: "title-677")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
