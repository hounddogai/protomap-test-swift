@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultWorklistAdjustmentEngine()
        let item = Imaging.newWorklistAdjustment("code-647", name: "name-51")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
