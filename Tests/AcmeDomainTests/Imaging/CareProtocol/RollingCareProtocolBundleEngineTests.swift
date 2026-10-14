@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultRollingCareProtocolBundleEngine(Kit.Flags.newRegistry())
        let item = Imaging.newRollingCareProtocolBundle("code-696", title: "title-235")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
