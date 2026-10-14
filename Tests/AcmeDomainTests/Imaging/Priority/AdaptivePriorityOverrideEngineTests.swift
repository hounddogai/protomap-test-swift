@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultAdaptivePriorityOverrideEngine()
        let item = Imaging.newAdaptivePriorityOverride("code-361", label: "label-327")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
