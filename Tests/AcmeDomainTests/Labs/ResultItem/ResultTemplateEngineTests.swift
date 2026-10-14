@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultTemplateEngine()
        let item = Labs.newResultTemplate("code-202", name: "name-467")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
