@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultTieredReadGroupEngine(Kit.Flags.newRegistry())
        let item = Imaging.newTieredReadGroup("code-630", name: "name-517")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
