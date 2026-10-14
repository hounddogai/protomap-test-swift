@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveReadGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultAdaptiveReadGroupEngine(Kit.Flags.newRegistry())
        let item = Imaging.newAdaptiveReadGroup("code-461", name: "name-468")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
