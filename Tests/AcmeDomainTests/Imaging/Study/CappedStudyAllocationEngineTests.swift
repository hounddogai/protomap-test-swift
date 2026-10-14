@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedStudyAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultCappedStudyAllocationEngine()
        let item = Imaging.newCappedStudyAllocation("code-248", label: "label-521")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
