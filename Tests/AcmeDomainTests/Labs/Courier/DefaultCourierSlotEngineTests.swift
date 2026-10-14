@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultDefaultCourierSlotEngine()
        let item = Labs.newDefaultCourierSlot("code-335", name: "name-681")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
