@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultWindowEngine(Kit.Flags.newRegistry())
        let item = Labs.newResultWindow("code-789", title: "title-544")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
