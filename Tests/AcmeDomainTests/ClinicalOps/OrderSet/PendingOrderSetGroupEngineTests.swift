@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingOrderSetGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultPendingOrderSetGroupEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newPendingOrderSetGroup("code-106", label: "label-208")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
