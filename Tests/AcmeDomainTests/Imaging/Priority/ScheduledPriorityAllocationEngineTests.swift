@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultScheduledPriorityAllocationEngine(Kit.Flags.newRegistry())
        let item = Imaging.newScheduledPriorityAllocation("code-802", name: "name-504")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
