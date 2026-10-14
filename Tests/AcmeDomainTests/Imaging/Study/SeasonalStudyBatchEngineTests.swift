@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalStudyBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultSeasonalStudyBatchEngine(Kit.Flags.newRegistry())
        let item = Imaging.newSeasonalStudyBatch("code-22", name: "name-86")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
