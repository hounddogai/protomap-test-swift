@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalPriorityCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultRegionalPriorityCycleEngine()
        let item = Imaging.newRegionalPriorityCycle("code-556", label: "label-160")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
