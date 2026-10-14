@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultAdaptiveSpecimenTemplateEngine(Kit.Flags.newRegistry())
        let item = Labs.newAdaptiveSpecimenTemplate("code-866", title: "title-58")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
