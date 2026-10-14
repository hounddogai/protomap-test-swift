@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRollingPanelMappingEngine(Kit.Flags.newRegistry())
        let item = Labs.newRollingPanelMapping("code-323", label: "label-282")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
