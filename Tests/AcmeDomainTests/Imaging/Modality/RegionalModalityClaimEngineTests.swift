@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalModalityClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultRegionalModalityClaimEngine(Kit.Flags.newRegistry())
        let item = Imaging.newRegionalModalityClaim("code-647", label: "label-847")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
