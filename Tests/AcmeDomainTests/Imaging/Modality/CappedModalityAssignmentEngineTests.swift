@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultCappedModalityAssignmentEngine(Kit.Flags.newRegistry())
        let item = Imaging.newCappedModalityAssignment("code-222", title: "title-990")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
