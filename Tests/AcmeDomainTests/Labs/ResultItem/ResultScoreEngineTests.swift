@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultScoreEngine(Kit.Flags.newRegistry())
        let item = Labs.newResultScore("code-944", name: "name-985")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
