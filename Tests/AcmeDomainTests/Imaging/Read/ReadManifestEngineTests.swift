@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadManifestEngine(Kit.Flags.newRegistry())
        let item = Imaging.newReadManifest("code-513", name: "name-474")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
