@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultModalityAssignmentEngine()
        let item = Imaging.newModalityAssignment("code-939", name: "name-102")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
