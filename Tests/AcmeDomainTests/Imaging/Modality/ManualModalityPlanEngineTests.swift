@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualModalityPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultManualModalityPlanEngine()
        let item = Imaging.newManualModalityPlan("code-87", title: "title-893")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
