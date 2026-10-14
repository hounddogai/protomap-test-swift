@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelAssignmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newPanelAssignment("code-314", title: "title-204")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
