@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelRecordEngine()
        let item = Labs.newPanelRecord("code-876", label: "label-584")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
