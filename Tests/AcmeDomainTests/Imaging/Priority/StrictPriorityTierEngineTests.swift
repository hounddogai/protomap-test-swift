@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictPriorityTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultStrictPriorityTierEngine(Kit.Flags.newRegistry())
        let item = Imaging.newStrictPriorityTier("code-527", label: "label-999")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
