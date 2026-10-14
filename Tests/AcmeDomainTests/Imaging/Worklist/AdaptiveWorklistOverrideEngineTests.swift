@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveWorklistOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultAdaptiveWorklistOverrideEngine(Kit.Flags.newRegistry())
        let item = Imaging.newAdaptiveWorklistOverride("code-85", label: "label-378")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
