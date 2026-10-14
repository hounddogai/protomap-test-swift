@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyCourierWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLegacyCourierWindowEngine(Kit.Flags.newRegistry())
        let item = Labs.newLegacyCourierWindow("code-347", title: "title-751")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
