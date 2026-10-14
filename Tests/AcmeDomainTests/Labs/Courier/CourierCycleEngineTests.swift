@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierCycleEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierCycle("code-406", name: "name-195")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
