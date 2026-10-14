@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultSlotEngine(Kit.Flags.newRegistry())
        let item = Labs.newResultSlot("code-959", label: "label-858")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
