@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedStudyBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultWeightedStudyBundleEngine(Kit.Flags.newRegistry())
        let item = Imaging.newWeightedStudyBundle("code-771", label: "label-984")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
