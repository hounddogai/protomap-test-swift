@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedResultCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCappedResultCycleEngine()
        let item = Labs.newCappedResultCycle("code-207", label: "label-532")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
