@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelRollupEngine(Kit.Flags.newRegistry())
        let item = Labs.newPanelRollup("code-767", title: "title-789")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
