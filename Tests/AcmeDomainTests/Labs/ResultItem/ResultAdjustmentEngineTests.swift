@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultAdjustmentEngine()
        let item = Labs.newResultAdjustment("code-604", name: "name-292")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
