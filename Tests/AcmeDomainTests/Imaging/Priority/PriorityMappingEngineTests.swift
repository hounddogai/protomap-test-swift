@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPriorityMappingEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPriorityMapping("code-308", name: "name-330")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
