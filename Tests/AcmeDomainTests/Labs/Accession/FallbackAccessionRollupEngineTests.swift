@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultFallbackAccessionRollupEngine()
        let item = Labs.newFallbackAccessionRollup("code-372", title: "title-477")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
