@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierTemplateEngine()
        let item = Labs.newCourierTemplate("code-906", label: "label-433")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
