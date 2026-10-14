@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPriorityAllocationEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPriorityAllocation("code-299", title: "title-456")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
