@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultStudyTargetEngine()
        let item = Imaging.newStudyTarget("code-173", label: "label-386")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
