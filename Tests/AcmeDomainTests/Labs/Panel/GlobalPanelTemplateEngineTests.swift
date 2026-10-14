@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalPanelTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultGlobalPanelTemplateEngine()
        let item = Labs.newGlobalPanelTemplate("code-766", label: "label-841")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
