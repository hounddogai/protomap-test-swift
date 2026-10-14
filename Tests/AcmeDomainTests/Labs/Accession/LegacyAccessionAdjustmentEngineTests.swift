@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLegacyAccessionAdjustmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newLegacyAccessionAdjustment("code-907", name: "name-252")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
