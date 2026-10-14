@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredResultRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultTieredResultRequestEngine(Kit.Flags.newRegistry())
        let item = Labs.newTieredResultRequest("code-108", title: "title-588")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
