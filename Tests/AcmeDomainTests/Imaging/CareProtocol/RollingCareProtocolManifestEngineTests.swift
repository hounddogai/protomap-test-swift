@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultRollingCareProtocolManifestEngine(Kit.Flags.newRegistry())
        let item = Imaging.newRollingCareProtocolManifest("code-231", label: "label-723")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
