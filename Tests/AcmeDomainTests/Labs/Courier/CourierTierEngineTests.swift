@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierTierEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierTier("code-747", name: "name-673")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
