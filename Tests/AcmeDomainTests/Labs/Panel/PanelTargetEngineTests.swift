@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelTargetEngine(Kit.Flags.newRegistry())
        let item = Labs.newPanelTarget("code-368", title: "title-998")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
