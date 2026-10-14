@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingOrderSetWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultRollingOrderSetWindowEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newRollingOrderSetWindow("code-280", name: "name-968")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
