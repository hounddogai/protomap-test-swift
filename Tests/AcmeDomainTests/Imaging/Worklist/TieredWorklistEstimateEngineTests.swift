@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredWorklistEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultTieredWorklistEstimateEngine(Kit.Flags.newRegistry())
        let item = Imaging.newTieredWorklistEstimate("code-152", title: "title-277")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
