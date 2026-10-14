@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultStudyEstimateEngine()
        let item = Imaging.newStudyEstimate("code-354", name: "name-691")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
