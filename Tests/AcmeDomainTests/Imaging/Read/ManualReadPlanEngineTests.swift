@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualReadPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultManualReadPlanEngine(Kit.Flags.newRegistry())
        let item = Imaging.newManualReadPlan("code-524", name: "name-775")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
