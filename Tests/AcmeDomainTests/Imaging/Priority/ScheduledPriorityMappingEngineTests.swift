@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultScheduledPriorityMappingEngine()
        let item = Imaging.newScheduledPriorityMapping("code-177", title: "title-1")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
