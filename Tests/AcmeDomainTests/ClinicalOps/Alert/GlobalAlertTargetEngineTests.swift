@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalAlertTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultGlobalAlertTargetEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newGlobalAlertTarget("code-784", label: "label-341")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
