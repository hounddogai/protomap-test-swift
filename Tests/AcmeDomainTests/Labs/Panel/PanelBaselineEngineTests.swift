@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelBaselineEngine(Kit.Flags.newRegistry())
        let item = Labs.newPanelBaseline("code-335", title: "title-574")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
