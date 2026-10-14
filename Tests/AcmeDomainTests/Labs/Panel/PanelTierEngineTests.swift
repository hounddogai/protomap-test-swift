@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelTierEngine(Kit.Flags.newRegistry())
        let item = Labs.newPanelTier("code-653", label: "label-302")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
