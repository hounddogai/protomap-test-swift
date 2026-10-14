@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelMappingEngine()
        let item = Labs.newPanelMapping("code-653", name: "name-310")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
