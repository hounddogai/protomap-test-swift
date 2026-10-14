@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultAlertBaselineEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newAlertBaseline("code-486", title: "title-753")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
