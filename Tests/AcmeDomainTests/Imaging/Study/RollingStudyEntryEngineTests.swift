@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudyEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultRollingStudyEntryEngine()
        let item = Imaging.newRollingStudyEntry("code-604", name: "name-637")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
