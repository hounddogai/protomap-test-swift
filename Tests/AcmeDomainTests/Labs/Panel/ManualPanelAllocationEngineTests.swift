@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualPanelAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultManualPanelAllocationEngine(Kit.Flags.newRegistry())
        let item = Labs.newManualPanelAllocation("code-72", title: "title-685")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
