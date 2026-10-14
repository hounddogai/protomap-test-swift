@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalOrderSetTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultSeasonalOrderSetTemplateEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newSeasonalOrderSetTemplate("code-171", label: "label-755")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
