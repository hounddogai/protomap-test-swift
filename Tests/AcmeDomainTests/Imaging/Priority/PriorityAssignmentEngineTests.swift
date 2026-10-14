@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPriorityAssignmentEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPriorityAssignment("code-894", label: "label-663")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
