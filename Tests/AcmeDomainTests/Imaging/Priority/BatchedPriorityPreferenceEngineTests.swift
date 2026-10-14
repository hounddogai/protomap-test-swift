@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedPriorityPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultBatchedPriorityPreferenceEngine(Kit.Flags.newRegistry())
        let item = Imaging.newBatchedPriorityPreference("code-507", name: "name-952")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
