@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultStudyVarianceEngine()
        let item = Imaging.newStudyVariance("code-666", title: "title-711")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
