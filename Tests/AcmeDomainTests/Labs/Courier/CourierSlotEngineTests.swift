@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierSlotEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierSlot("code-678", name: "name-232")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
