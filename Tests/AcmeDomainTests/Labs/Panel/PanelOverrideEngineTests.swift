@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelOverrideEngine()
        let item = Labs.newPanelOverride("code-681", title: "title-144")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
