@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalReadDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultGlobalReadDigestEngine(Kit.Flags.newRegistry())
        let item = Imaging.newGlobalReadDigest("code-81", name: "name-154")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
